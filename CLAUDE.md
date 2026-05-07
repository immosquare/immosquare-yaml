# immosquare-yaml

Psych post-processor for Rails translation files. Loads a YAML file, returns a clean hash, and re-emits deterministically formatted YAML.

## Architecture

```
parse(file)
  └─ Psych.parse_file       # robust AST (handles anchors, multi-doc, escapes, etc.)
  └─ node_to_value          # recursive AST walker → Hash/Array/String/nil
       └─ scalar_to_ruby    # Norway problem handled here (yes/no stay String)

dump(hash)
  └─ recursive render       # Hash → YAML String
       ├─ nil       → " null"
       ├─ Hash      → indented recursion
       ├─ Array     → delegated to Psych.dump then re-indented
       └─ String    → format_scalar_value
            ├─ contains \n           → literal block | or |-
            ├─ needs quoting         → single or double-quoted
            └─ otherwise             → plain

clean(file) = parse + (sort) + dump → write
```

**Key point**: we do not rewrite a homemade YAML parser. We rely on Psych for reading (AST) and do our own serialization to control the output format.

## Public API

| Method                                            | Description                                                                       |
| ------------------------------------------------- | --------------------------------------------------------------------------------- |
| `parse(file_path, sort: true)`                    | YAML file → Ruby hash. Returns `{}` for an empty file, `false` on error.          |
| `clean(file_path, sort: true, output: file_path)` | Sanitize YAML file (parse + sort + dump).                                         |
| `dump(hash)`                                      | Ruby hash → YAML string.                                                          |

## Guarantees (the 5 criteria that justify this gem)

1. **Norway problem** — `yes`/`no`/`on`/`off`/`true`/`false` in plain style stay as `String` on parse, and are quoted on dump so they round-trip as String.
2. **Deterministic ordering** — keys sorted alphabetically by default (`sort: false` to keep insertion order).
3. **Literal blocks preserved** — any string containing `\n` is re-emitted as `|` (with trailing `\n`) or `|-` (without trailing `\n`).
4. **Minimal quoting** — plain by default. Single-quoted as soon as quoting is needed. Double-quoted only if the value contains `'`, `\`, or `\t`.
5. **`\U0001F600` decoding** — converted to UTF-8 emoji on dump.

## Output formatting rules

- **Keys**:
  - Numeric (`1`, `2`, `10`) → quoted `"1":`
  - YAML 1.1 reserved words (`yes`, `no`, etc.) → quoted `"yes":`
  - Otherwise plain
- **Scalar values**:
  - String containing `\n` → literal block `|` or `|-`
  - String with a quoting trigger (`: `, ` #`, YAML-special start, trailing `:`, edge whitespace, reserved word) → quoted
  - Style choice: **single-quoted by default**; double-quoted only if the value contains `'`, `\` or `\t`
  - Otherwise plain
- **`nil`** → literal `null`
- **`Array`** → delegated to `Psych.dump` then re-indented
- **Typographic quotes** (`’`, `‘`, `“`, `”`) → normalized to `'` / `"` on dump

## Tests

```bash
bundle exec rspec
```

Suite: 71 tests across 2 spec files.

- `spec/immosquare-yaml_spec.rb` — tests of the public API (parse/clean/dump) against `sample.en.yml` + `edge_cases.fr.yml`
- `spec/immosquare-yaml_edge_cases_spec.rb` — 53 assertions across 21 edge-case categories (Norway, numeric keys, deep nesting, interpolations, pluralization, HTML, emojis, typographic quotes, folded scalars, literal blocks, lists, special characters, quoting, null, currencies, naming)

All test artifacts are written to `Dir.mktmpdir` (auto-cleanup), never inside the gem's tree.

## Rake Tasks (dev)

```bash
bundle exec rake immosquare_yaml:sample:parse    # Parse YAML to JSON
bundle exec rake immosquare_yaml:sample:clean    # Clean YAML file
bundle exec rake immosquare_yaml:sample:dump     # Dump JSON to YAML
```

## What the gem does NOT do

- No preservation of YAML comments (Psych drops them at parse time).
- No preservation of anchors/aliases as anchors (resolved into duplicated values).
- No multi-document support (multiple `---` separators) — only the first document is read.
- Not for generic YAML with Ruby objects or custom tags — use Psych directly in that case.
