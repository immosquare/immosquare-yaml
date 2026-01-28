# immosquare-yaml

Ruby gem for parsing, dumping, and cleaning YAML translation files. Solves issues with standard YAML parsers (Psych) that interpret `yes`, `no`, `on`, `off`, `true`, `false` as booleans.

## Rake Tasks (dev/test)

```bash
bundle exec rake immosquare_yaml:sample:parse    # Parse YAML to JSON
bundle exec rake immosquare_yaml:sample:clean    # Clean YAML file
bundle exec rake immosquare_yaml:sample:dump     # Dump JSON to YAML
```

## Public API

| Méthode | Description |
|---------|-------------|
| `parse(file_path, sort: true)` | YAML file → Ruby hash |
| `clean(file_path, sort: true, output: file_path)` | Sanitize YAML file |
| `dump(hash)` | Ruby hash → YAML string |

## YAML Formatting Rules

- Integer keys quoted: `"1": value`
- Reserved keys quoted: `"yes": value`
- Values with `: `, ` #`, or newlines are quoted
- Emoji codes (`\U0001F600`) converted to actual emojis
- Curly/typographic quotes normalized to standard quotes
