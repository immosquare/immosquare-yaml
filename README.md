# ImmosquareYaml

ImmosquareYaml is a specialized Ruby gem primarily tailored for parsing and dumping YML translation files. Its capabilities, however, are not limited to translations, as it showcases an adeptness in managing any YML file seamlessly.

In the past, there have been significant challenges in using existing YAML parsers like [Psych](https://github.com/ruby/psych) and [YAML](https://github.com/ruby/yaml) (which internally utilizes Psych). Issues arose, such as interpreting translation keys like `yes:`, `no:`, and others as booleans. Additionally, they showed shortcomings in effectively handling multiline texts, often faltering with notations like `key: |`, `key: |-`, `key: >`, `key: |5+`, `key: |3-`, and more.

### Why Choose ImmosquareYaml?
Here are some standout features and advantages of this gem:

- **Reserved Key Management**: Handles keys with "reserved" words seamlessly.
- **Complete Multiline Handling**: Efficiently processes multiline texts using various notations.
- **Value Uniformization**: Retains double quotes only when essential, ensuring a clean and readable output.
- **Emoji Handling**: Comprehensive management of emojis in YAML files.
- **Sorting Capability**: Offers sorting (enabled by default) during the cleaning or parsing phase for a structured representation.
- **Automatic Translations**: Features an automatic translation of YML files, leveraging the artificial intelligence of OpenAI.
- **Optimized for Translations**: Precisely tailored for handling translation files, addressing challenges faced with other parsers.

Whether you're managing translations, real estate data, or any other form of YML data, ImmosquareYaml offers a refined, efficient, and user-friendly experience. Dive in and simplify your YAML operations!


## Installation

Add this line to your Gemfile:

```ruby
gem 'immosquare-yaml'
```

And then execute:

```sh
bundle install
```

Or install it yourself as:

```sh
gem install immosquare-yaml
```

## Usage

### Parsing YAML Files

To parse a YAML file and transform it into a Ruby hash, use the `ImmosquareYaml.parse` method:

```ruby
hash = ImmosquareYaml.parse('path/to/your/file.yml')
```

By default, the resulting hash will be sorted. If you do not wish to sort the hash, pass the `:sort => false` option:

```ruby
hash = ImmosquareYaml.parse('path/to/your/file.yml', :sort => false)
```

### Cleaning YAML Files

To clean a YAML file, use the `ImmosquareYaml.clean` method:

```ruby
ImmosquareYaml.clean('path/to/your/file.yml')
```

As with the `parse` method, the file will be sorted by default after cleaning. If you do not wish to sort the file, pass the `:sort => false` option:

```ruby
ImmosquareYaml.clean('path/to/your/file.yml', :sort => false)
```

### Creating YAML Files

To create a YAML file from a Ruby hash, use the `ImmosquareYaml.dump` method:

```ruby
hash = { 'a' => 1, 'b' => 2 }
ImmosquareYaml.dump(hash, 'path/to/your/new/file.yml')
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on our [GitHub repository](https://github.com/IMMOSQUARE/immosquare-yaml).

## License

This gem is available under the terms of the [MIT License](https://opensource.org/licenses/MIT).
