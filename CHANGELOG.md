## [1.0.2] - 2026-05-08

### Added
- `flatten_keys(input, **options)`: flatten a Hash, a YAML file path, or an `Array<String>` of paths into sorted dot-separated paths. Reserved YAML 1.1 segments (`yes`/`no`/`true`/...) and purely numeric segments are quoted in the output for safe round-tripping. Optional `with_values` and `with_file` return `[path, value]`, `[path, file]` or `[path, value, file]` tuples. Empty nested hashes are skipped. Sort is deterministic across multi-file inputs (ties broken by source file).
- `parse_path(dot_path)`: symmetric inverse of `flatten_keys` segment quoting — returns an `Array<String>` ready for `Hash#dig` on a hash returned by `parse`.

## [1.0.1] - 2026-05-07

### Changed
- `dump`: invert default scalar quoting style. Values needing quotes are now emitted double-quoted by default; single-quoted is reserved for values containing `"` or `\` (and no `\t`). Aligns YAML output with the project-wide Ruby double-quote convention.

## [1.0.0] - 2026-05-07

### Changed
- Rewrite parser and dumper on top of the Psych AST. The previous line-by-line `clean_yml`/`parse_xml` pipeline is removed; `parse` now walks `Psych.parse_file` directly, and `dump` is split into a public single-argument `dump(hash)` plus a private `render_hash`. Norway problem, literal block preservation (`|` / `|-`), minimal quoting (single-quoted by default, double-quoted only when `'`, `\` or `\t` are present) and `\U0001F600` decoding are now handled at the AST/scalar level.
- Mission scope refocused on Rails translation files (README and CLAUDE.md rewritten accordingly).

### Added
- `spec/fixtures/edge_cases.fr.yml` and `spec/immosquare-yaml_edge_cases_spec.rb` covering 21 categories: Norway problem, numeric keys, deep nesting, Rails interpolation, pluralization, inline HTML, emojis, typographic quotes, folded scalars, literal blocks, lists, special leading characters, quoting triggers, null values, currencies and key naming conventions.

### Removed
- Internal `clean_yml`, `parse_xml` and the line-by-line preprocessing helpers.
- Undocumented positional arguments on `dump` (`lines`, `indent`) — now strictly `dump(hash)`.

## [0.1.28] - 2025-09-03
- Add missing require of fileutils

## [0.1.27] - 2024-11-28
- fix case with RESERVED_KEYS.include in value

## [0.1.26] - 2024-03-15
- Move translate Module to seperate gem

## [0.1.25] - 2024-03-15
- Fix Price

## [0.1.24] - 2024-03-15
- Add new model gpt-4-0125-preview

## [0.1.23] - 2024-03-04
- Fix new improvement for nil value

## [0.1.22] - 2024-03-04
- Improve Translate Module for complexe Yaml files

## [0.1.21] - 2024-02-06
- bump immosquare-exentension gem version

## [0.1.20] - 2024-02-05
- File.normalize_last_line from immosquare-exentension gem

## [0.1.19] - 2023-11-10
- Add new model gpt-4-1106-preview

## [0.1.18] - 2023-10-10
- Fixbug with yml lists

## [0.1.17] - 2023-09-30
- Manage yml lists

## [0.1.16] - 2023-09-30
- bump immosquare-extensions

## [0.1.15] - 2023-09-30
- Improve sort_by_key method

## [0.1.14] - 2023-09-30
- Add min version for immosquare-extensions

## [0.1.13] - 2023-09-30
- Add immosquare-extensions

## [0.1.12] - 2023-09-29
- Improve normalize_last_line

## [0.1.11] - 2023-09-29
- Fix bug

## [0.1.10] - 2023-09-29
- Improve normalize_last_line

## [0.1.9] - 2023-09-25
- Improve prompt to avoid comments

## [0.1.8] - 2023-09-25
- Increase timeout

## [0.1.7] - 2023-09-25
- fix bug with RESET_TRANSLATIONS flag

## [0.1.6] - 2023-09-25
- fix bug with RESET_TRANSLATIONS flag

## [0.1.5] - 2023-09-25
- Add RESET_TRANSLATIONS flag to immosquare_yaml:translate task

## [0.1.4] - 2023-09-24
- Add params to task (rake immosquare_yaml:translate LOCALE="en")

## [0.1.3] - 2023-09-24
- Fix OpenAI Api return

## [0.1.2] - 2023-09-24
- Add Tranlate Module

- Add Tasks for rails App

## [0.1.1] - 2023-09-21
- Added tasks for improved development workflow.

- Introduced RSpec tests to enhance code reliability and maintainability.

## [0.1.0] - 2023-09-21
- Initial release
