# ImmosquareYaml

ImmosquareYaml is a Ruby gem that facilitates the manipulation of YAML files. It allows you to parse, clean, and create YAML files from Ruby hashes.

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
