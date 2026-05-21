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

| Method                                                 | Returns          | Purpose                                                                                  |
| ------------------------------------------------------ | ---------------- | ---------------------------------------------------------------------------------------- |
| `ImmosquareYaml.parse(path, sort: true)`               | `Hash`           | Parse a YAML file into a Ruby hash. Sorted by key by default.                            |
| `ImmosquareYaml.clean(path, sort: true, output: path)` | `Boolean`        | Parse, sort, re-emit. Overwrites the file by default; pass `:output` to write elsewhere. |
| `ImmosquareYaml.dump(hash)`                            | `String`         | Serialize a Ruby hash to a YAML string with the same formatting rules as `clean`.        |
| `ImmosquareYaml.flatten_keys(input, **options)`        | `Array`          | Flatten a hash or YAML file path(s) into dot-separated paths.                            |
| `ImmosquareYaml.parse_path(dot_path)`                  | `Array<String>`  | Inverse of `flatten_keys` segment quoting — produces an array usable with `Hash#dig`.    |
| `ImmosquareYaml.delete_paths(path, paths, **options)`  | `Hash` / `false` | Remove one or more dot-paths from a YAML file, prune empty parents, rewrite via `dump`.  |

`parse`, `clean` and `dump` preserve the guarantees below. `flatten_keys`, `parse_path` and `delete_paths` are flat-path utilities built on top of `parse` and inherit them transitively.

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

Strings are emitted plain whenever YAML allows it. Quotes appear only when the value would be ambiguous: contains `: `, ` #`, leading or trailing whitespace, starts with a YAML special character, ends with `:`, or matches a reserved word.

When quoting is required, double-quoted is used by default. Single-quoted is used only when the value contains `"` or `\` (and no `\t`, which can only be encoded in double-quoted form).

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

### Flatten keys

`flatten_keys` turns nested translation data into a flat list of dot-separated paths. It accepts any of the following:

- a `Hash` — flattened directly, no I/O
- a single file path (`String`)
- an `Array<String>` of file paths

Globs are not expanded — pass `Dir.glob(...)` upstream if you need that. Mixing a `Hash` with file paths in the same call is not supported.

Reserved YAML 1.1 segments (`yes`, `no`, `true`, `false`, `on`, `off`, ...) and purely numeric segments (`"42"`) are wrapped in double quotes inside the resulting paths so they can be re-fed to `I18n.t` or written back to YAML without ambiguity. Empty nested hashes are skipped (no path emitted).

```ruby
##============================================================##
## From a Hash
##============================================================##
hash = {
  "fr" => {
    "app" => {
      "title" => "Titre",
      "body"  => "Corps"
    }
  }
}

ImmosquareYaml.flatten_keys(hash)
# => ["fr.app.body", "fr.app.title"]

##============================================================##
## From a single file
##============================================================##
ImmosquareYaml.flatten_keys("config/locales/fr.yml")
# => ["fr.app.body", "fr.app.title", "fr.app.welcome", ...]

##============================================================##
## From an Array of file paths (expand globs upstream)
##============================================================##
ImmosquareYaml.flatten_keys(Dir.glob("config/locales/**/*.yml"))
# => ["en.app.body", "en.app.title", "fr.app.body", "fr.app.title", ...]

##============================================================##
## With values (every leaf is kept, no dedup)
##============================================================##
ImmosquareYaml.flatten_keys(hash, :with_values => true)
# => [["fr.app.body", "Corps"], ["fr.app.title", "Titre"]]

##============================================================##
## With source file (added as third element when combined
## with :with_values, or as second element on its own)
##============================================================##
ImmosquareYaml.flatten_keys("config/locales/fr.yml", :with_file => true)
# => [["fr.app.body", "config/locales/fr.yml"], ...]

ImmosquareYaml.flatten_keys(hash, :with_values => true, :with_file => true)
# => [["fr.app.body", "Corps", nil], ["fr.app.title", "Titre", nil]]
##  ^^ file is nil for entries coming from a Hash
```

Reserved and numeric keys are quoted in the output:

```ruby
hash = {"fr" => {"statuses" => {"yes" => "Oui", "42" => "x"}}}
ImmosquareYaml.flatten_keys(hash)
# => ["fr.statuses.\"42\"", "fr.statuses.\"yes\""]
```

### Parse a dot-path

`parse_path` is the symmetric inverse of the segment quoting done by `flatten_keys`. It splits a dot-path on `.` and strips wrapping `"..."` from quoted segments, returning an `Array<String>` ready to be passed to `Hash#dig` on a hash returned by `ImmosquareYaml.parse`.

> Limitation: keys containing a literal `.` are not supported — the dot is always treated as a segment separator.

```ruby
ImmosquareYaml.parse_path("fr.app.title")
# => ["fr", "app", "title"]

ImmosquareYaml.parse_path("fr.statuses.\"yes\"")
# => ["fr", "statuses", "yes"]

ImmosquareYaml.parse_path("fr.counts.\"42\"")
# => ["fr", "counts", "42"]
```

Round-trip example:

```ruby
hash = ImmosquareYaml.parse("config/locales/fr.yml")

ImmosquareYaml.flatten_keys(hash).each do |path|
  value = hash.dig(*ImmosquareYaml.parse_path(path))
  puts "#{path} = #{value.inspect}"
end
```

### Delete paths

`delete_paths` removes one or more dot-paths from a YAML file. The file is parsed, leaves are deleted, empty parent maps are pruned recursively, and the result is rewritten through `dump` so the formatting (sort, quoting, literal blocks) is preserved.

It accepts a single path or an `Array<String>`. Reserved (`yes`, `no`, `true`, ...) and purely numeric segments must be wrapped in `"..."`, exactly like the output of `flatten_keys`.

```ruby
##  Remove a single key
ImmosquareYaml.delete_paths("config/locales/fr.yml", "fr.app.leases.statuses.archived")
##  => { :deleted => ["fr.app.leases.statuses.archived"], :not_found => [] }

##  Remove several at once — empty parents are pruned automatically
ImmosquareYaml.delete_paths("config/locales/fr.yml", [
  "fr.app.leases.title",
  "fr.app.leases.statuses.active",
  "fr.app.leases.statuses.archived"
])
##  => { :deleted => [...], :not_found => [...] }

##  Reserved or numeric segments are quoted in the dot-path
ImmosquareYaml.delete_paths("config/locales/fr.yml", "fr.statuses.\"yes\"")

##  Write to a different output instead of overwriting in place
ImmosquareYaml.delete_paths("config/locales/fr.yml", "fr.app.foo", :output => "tmp/cleaned.fr.yml")

##  Keep insertion order instead of sorting (default: sort: true)
ImmosquareYaml.delete_paths("config/locales/fr.yml", "fr.app.foo", :sort => false)
```

Returns `false` if the file cannot be parsed (or if its root is not a mapping). Returns `{:deleted, :not_found}` otherwise — paths that don't exist in the file are simply reported in `:not_found`, never raised.

> **Note** : the file is always rewritten through `dump`, even when every path is reported as `:not_found`. Calling `delete_paths` therefore doubles as a `clean` (sort + reformat) on the target file. Pass `:output => "..."` if you want to write elsewhere instead of overwriting in place.

---

## How it works

`parse` calls `Psych.parse_file` to get a YAML AST, then walks it:

- `Psych::Nodes::Mapping` → Ruby `Hash` (keys always cast to `String`)
- `Psych::Nodes::Sequence` → Ruby `Array`
- `Psych::Nodes::Scalar` → `String`, `Integer`, `Float` or `nil`, with the Norway exception applied at the leaf

`dump` walks the resulting hash and writes YAML manually:

- Reserved or numeric keys are wrapped in double quotes
- Strings containing `\n` are emitted as `|` or `|-` blocks
- Strings that would be ambiguous in plain form are double-quoted by default; values containing `"` or `\` (and no `\t`) are single-quoted instead, with `'` doubled
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

MIT.
