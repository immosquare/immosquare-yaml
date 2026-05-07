# ImmosquareYaml

A thin Psych post-processor for Rails translation files (`config/locales/*.yml`).

The Ruby standard library's [Psych](https://github.com/ruby/psych) parses YAML correctly but is not opinionated about how the output should look. For translation files, that creates real-world friction:

- `yes:`, `no:`, `on:`, `off:` keys are interpreted as booleans (the [Norway problem](https://hitchdev.com/strictyaml/why/implicit-typing-removed/))
- Keys are emitted in arbitrary order, making git diffs noisy
- Block literals (`|`, `|-`) get rewritten with surprising indentation choices
- Strings are quoted defensively even when not needed
- Unicode escapes like `\U0001F600` survive instead of becoming actual emojis

ImmosquareYaml takes a YAML file in, returns a Hash, or writes back a clean, sorted, human-readable YAML file out. Internally it walks the Psych AST — it is not a parser.

---

## Installation

```ruby
gem "immosquare-yaml"
```

```bash
bundle install
```

---

## Public API

| Method                                                 | Returns   | Purpose                                                                                  |
| ------------------------------------------------------ | --------- | ---------------------------------------------------------------------------------------- |
| `ImmosquareYaml.parse(path, sort: true)`               | `Hash`    | Parse a YAML file into a Ruby hash. Sorted by key by default.                            |
| `ImmosquareYaml.clean(path, sort: true, output: path)` | `Boolean` | Parse, sort, re-emit. Overwrites the file by default; pass `:output` to write elsewhere. |
| `ImmosquareYaml.dump(hash)`                            | `String`  | Serialize a Ruby hash to a YAML string with the same formatting rules as `clean`.        |

All three preserve the five guarantees below.

---

## What it guarantees

### 1. Norway problem — reserved words stay strings

```yaml
# input
en:
  yes: This is not a boolean
  no: Neither is this
  reserved_words:
    yes: yes
    no: no
```

```ruby
ImmosquareYaml.parse("locales.en.yml")
# => {
#   "en" => {
#     "yes" => "This is not a boolean",
#     "no"  => "Neither is this",
#     "reserved_words" => { "yes" => "yes", "no" => "no" }
#   }
# }
```

After `clean`, reserved keys and values are quoted so a vanilla `YAML.load` round-trips correctly:

```yaml
en:
  "no": Neither is this
  reserved_words:
    "no": "no"
    "yes": "yes"
  "yes": This is not a boolean
```

### 2. Deterministic key order

Keys are sorted alphabetically by default. Stable diffs, no merge conflicts on key reorders. Pass `sort: false` to keep insertion order.

### 3. Literal block scalars (`|` and `|-`) preserved

```yaml
# input
en:
  description: |
    Line 1.
    Line 2.
    Line 3.
```

`parse` returns `"Line 1.\nLine 2.\nLine 3.\n"`, and `clean` re-emits the exact same `|` block.

### 4. Minimal quoting

Strings are emitted plain whenever YAML allows it. Quotes appear only when the value would be ambiguous: contains `: `, ` #`, leading or trailing whitespace, starts with a YAML special character, ends with `:`, or matches a reserved word. Embedded double quotes are escaped (`\"`).

### 5. Unicode escapes decoded

```yaml
# input
en:
  emoji: "Bravo \U0001F600"
```

```yaml
# after clean
en:
  emoji: Bravo 😀
```

---

## Usage

### Parse

```ruby
hash = ImmosquareYaml.parse("config/locales/en.yml")
hash = ImmosquareYaml.parse("config/locales/en.yml", :sort => false)
```

Returns `false` if the file does not exist or cannot be parsed. Returns `{}` for empty files.

### Clean

```ruby
##============================================================##
## Overwrite the file in place
##============================================================##
ImmosquareYaml.clean("config/locales/en.yml")

##============================================================##
## Write to a different path
##============================================================##
ImmosquareYaml.clean("config/locales/en.yml", :output => "tmp/cleaned.yml")

##============================================================##
## Keep insertion order
##============================================================##
ImmosquareYaml.clean("config/locales/en.yml", :sort => false)
```

### Dump

```ruby
yaml = ImmosquareYaml.dump({
  "en" => {
    "yes"   => "This is not a boolean",
    "emoji" => "Bravo \u{1F600}"
  }
})

File.write("config/locales/en.yml", yaml)
```

---

## How it works

`parse` calls `Psych.parse_file` to get a YAML AST, then walks it:

- `Psych::Nodes::Mapping` → Ruby `Hash` (keys always cast to `String`)
- `Psych::Nodes::Sequence` → Ruby `Array`
- `Psych::Nodes::Scalar` → `String`, `Integer`, `Float` or `nil`, with the Norway exception applied at the leaf

`dump` walks the resulting hash and writes YAML manually:

- Reserved or numeric keys are wrapped in double quotes
- Strings containing `\n` are emitted as `|` or `|-` blocks
- Strings that would be ambiguous in plain form are double-quoted, with `\`, `"` and tabs properly escaped
- Arrays are delegated to `Psych.dump` and re-indented to match the surrounding block

`clean` is just `parse` + (optional sort) + `dump`, written to disk.

---

## What it does NOT do

- It does not preserve YAML comments. Psych drops them at parse time, and so does this gem.
- It does not preserve YAML anchors (`&foo` / `*foo`) as anchors — they are resolved into duplicated values during parse. This is fine for translation files, which never use anchors in practice.
- It does not handle multi-document streams (`---` separators with multiple docs). Only the first document is read.
- It is not designed for arbitrary YAML — it is tuned for Rails translation files. If your file has Ruby objects, custom tags, or complex anchors, use Psych directly.

---

## Contributing

Issues and pull requests welcome at [github.com/immosquare/immosquare-yaml](https://github.com/immosquare/immosquare-yaml).

The test suite lives in `spec/`. Run it with:

```bash
bundle exec rspec
```

Edge-case fixtures live in `spec/fixtures/edge_cases.fr.yml` and exercise: the Norway problem, numeric keys, deep nesting, Rails interpolation, pluralization, inline HTML, emojis, typographic quote normalization, folded scalars, literal blocks, lists, special leading characters, quoting triggers, null values, formatted prices, and various key naming conventions.

---

## License

MIT — see [LICENSE](LICENSE).
