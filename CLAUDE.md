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

flatten_keys(input)
  └─ Hash | String path | Array<String> path
  └─ flatten_hash (per src)  # walks hash, builds [path, value, file] entries
       └─ quote_segment      # quotes RESERVED_KEYS / numeric segments
       └─ skips empty nested Hashes
  └─ format_entries          # filters/sorts according to with_values/with_file

parse_path(dot_path)
  └─ String#split(".") + unquote_segment per token  # inverse of quote_segment

delete_paths(file, paths)
  └─ parse(file) → hash
  └─ for each dot-path:
       └─ parse_path → segments
       └─ delete_at_segments (recursive)
            └─ deletes leaf, prunes empty parents on the way back up
  └─ dump(hash) → write
  └─ returns { :deleted => [...], :not_found => [...] }
```

**Key point**: we do not rewrite a homemade YAML parser. We rely on Psych for reading (AST) and do our own serialization to control the output format.

## Public API

| Method                                            | Description                                                                                    |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `parse(file_path, sort: true)`                    | YAML file → Ruby hash. Returns `{}` for an empty file, `false` on error.                       |
| `clean(file_path, sort: true, output: file_path)` | Sanitize YAML file (parse + sort + dump).                                                      |
| `dump(hash)`                                      | Ruby hash → YAML string.                                                                       |
| `flatten_keys(input, **options)`                  | Hash / file path / Array<String> of paths → list of dot-paths (optionally with values / file). |
| `parse_path(dot_path)`                            | Inverse of `flatten_keys` segment quoting → `Array<String>` ready for `Hash#dig`.              |
| `delete_paths(file, paths, **options)`            | Remove dot-paths from a YAML file, prune empty parents, rewrite via `dump`. Returns a report.  |

### `flatten_keys` — accepted inputs

- `Hash` — flattened directly, no I/O. `with_file: true` puts `nil` as the file column.
- `String` — a single YAML file path. Missing/empty/unreadable files are silently skipped.
- `Array<String>` — list of YAML file paths.

Globs are NOT expanded — callers expand them upstream (e.g. `Dir.glob`). Mixing a `Hash` with file paths in the same call is not supported.

### `flatten_keys` — options

- `with_values: false` (default) → `Array<String>` of paths, sorted + deduplicated.
- `with_values: true` → `Array<[path, value]>`, sorted by path, **not** deduplicated.
- `with_file: true` → adds the source file path. Combined with `with_values: true` returns triplets `[path, value, file]`. For Hash inputs, `file` is `nil`.

### Path quoting (round-trip with `parse_path`)

- Segments matching `SharedMethods::RESERVED_KEYS` (`yes`, `no`, `true`, `false`, `on`, `off`, ...) → wrapped in `"..."`.
- Segments matching `/\A[-+]?\d+\z/` (purely numeric) → wrapped in `"..."`.
- All other segments → emitted plain.
- Empty nested Hashes are skipped (no leaf emitted).
- `parse_path` strips wrapping `"..."` from any segment, so `flatten_keys` → `parse_path` → `Hash#dig` round-trips on the parsed YAML hash.
- Limitation: keys containing a literal `.` are not supported (treated as a segment separator).

## Guarantees (the 5 criteria that justify this gem)

1. **Norway problem** — `yes`/`no`/`on`/`off`/`true`/`false` in plain style stay as `String` on parse, and are quoted on dump so they round-trip as String.
2. **Deterministic ordering** — keys sorted alphabetically by default (`sort: false` to keep insertion order).
3. **Literal blocks preserved** — any string containing `\n` is re-emitted as `|` (with trailing `\n`) or `|-` (without trailing `\n`).
4. **Minimal quoting** — plain by default. Double-quoted as soon as quoting is needed. Single-quoted only if the value contains `"` or `\` (and no `\t`).
5. **`\U0001F600` decoding** — converted to UTF-8 emoji on dump.

## Output formatting rules

- **Keys**:
  - Numeric (`1`, `2`, `10`) → quoted `"1":`
  - YAML 1.1 reserved words (`yes`, `no`, etc.) → quoted `"yes":`
  - Otherwise plain
- **Scalar values**:
  - String containing `\n` → literal block `|` or `|-`
  - String with a quoting trigger (`: `, ` #`, YAML-special start, trailing `:`, edge whitespace, reserved word) → quoted
  - Style choice: **double-quoted by default**; single-quoted only if the value contains `"` or `\` (and no `\t`, which can only be encoded in double-quoted form)
  - Otherwise plain
- **`nil`** → literal `null`
- **`Array`** → delegated to `Psych.dump` then re-indented
- **Typographic quotes** (`’`, `‘`, `“`, `”`) → normalized to `'` / `"` on dump

## Tests

```bash
bundle exec rspec
```

Suite: 102 tests across 4 spec files.

- `spec/immosquare-yaml_spec.rb` — tests of the public API (parse/clean/dump) against `sample.en.yml` + `edge_cases.fr.yml`
- `spec/immosquare-yaml_edge_cases_spec.rb` — 53 assertions across 21 edge-case categories (Norway, numeric keys, deep nesting, interpolations, pluralization, HTML, emojis, typographic quotes, folded scalars, literal blocks, lists, special characters, quoting, null, currencies, naming)
- `spec/immosquare-yaml_flatten_keys_spec.rb` — `flatten_keys` (Hash / file / Array<String>, with_values, with_file, reserved & numeric quoting, empty Hash skip) and `parse_path` (split + unquote, symmetric round-trip with `Hash#dig`)
- `spec/immosquare-yaml_delete_paths_spec.rb` — `delete_paths` (single/array, deleted vs not_found report, empty-parent pruning, reserved & numeric segments, separate output path, missing file, empty file, format preservation)

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
