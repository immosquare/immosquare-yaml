# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ImmosquareYaml is a Ruby gem for parsing, dumping, and cleaning YAML translation files. It addresses issues with standard YAML parsers (Psych/YAML) that incorrectly interpret keys like `yes`, `no`, `on`, `off`, `true`, `false` as booleans, and provides robust multiline text handling.

## Common Commands

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run a single test
bundle exec rspec spec/immosquare-yaml_spec.rb

# Sample file operations (for development/testing)
bundle exec rake immosquare_yaml:sample:parse    # Parse sample YAML to JSON
bundle exec rake immosquare_yaml:sample:clean    # Clean sample YAML file
bundle exec rake immosquare_yaml:sample:dump     # Dump JSON back to YAML
```

## Architecture

### Core Module (`lib/immosquare-yaml.rb`)

The main `ImmosquareYaml` module provides three public methods:

- **`parse(file_path, sort: true)`** - Converts YAML file to Ruby hash
- **`clean(file_path, sort: true, output: file_path)`** - Sanitizes YAML file (cleans, parses, sorts, dumps)
- **`dump(hash)`** - Converts Ruby hash to YAML string

### Key Components

- **`SharedMethods`** (`lib/immosquare-yaml/shared_methods.rb`) - Constants and utilities including:
  - `RESERVED_KEYS` - Words that need quoting (yes/no/on/off/true/false variants)
  - `YML_SPECIAL_CHARS` - Characters requiring special handling
  - `deep_transform_values` - Recursive hash transformation

- **`Configuration`** (`lib/immosquare-yaml/configuration.rb`) - Optional OpenAI config for translation features

- **`Railtie`** (`lib/immosquare-yaml/railtie.rb`) - Rails integration, loads rake task for `rake immosquare_yaml:clean`

### Processing Pipeline

1. **`clean_yml`** (private) - Line-by-line file cleaning:
   - Handles multiline blocks (`|`, `|-`, `>`, `|4-`, etc.)
   - Normalizes indentation and whitespace
   - Assigns `null` to empty values
   - Processes "weirdblocks" (multi-line values in quotes)

2. **`parse_xml`** (private, misnomer - parses YAML) - Converts cleaned YAML to nested hash

3. **`dump`** - Converts hash back to YAML with proper formatting

### Special Handling

- Integer keys are always quoted: `"1": value`
- Reserved keys are always quoted: `"yes": value`
- Values with special characters (`: `, ` #`, newlines) are quoted
- Emoji codes (`\U0001F600`) are converted to actual emojis
- Weird quotes (curly, typographic) are normalized to standard quotes
