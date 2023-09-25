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

## Quick Example

Let's assume you have a YML file with some reserved keys, multiline texts, and emojis:

````YML
en:
  demo: "demo" 
  yes: "This is not a boolean"
  no: "Neither is this"
  emoji: "Here's an emoji: \U0001F600"
  demo2:
    demo2-1:
      demo2-1-1: "hello"
      demo2-1-2:
      demo2-1-3: "John Doe"
  demo3:
    1: "task #1"
    2: "task #2"
    3: "task #2"
  some_special_characters:
    special1: "-hyphen"
    special2: "*asterisk"
    special3: "%percent"
    special4: ",comma"
    special5: "!exclamation"
    special6: "?question_mark"
    special7: "&ampersand"
    special8: "#hash"
    special9: "@at"
  description1: "This is the first line of test #1 \U0001F600.\nThis is the second line of test#1.\nThis is the third line of test.#1"
  description2: |
    This is the first line of test #2 \U0001F600.
    This is the second line of test #2.
    This is the third line of test #2.
  description3: |4-
      This is the first line of test #3 \U0001F600.
      This is the second line of test #3.
      This is the third line of test #3.
  description4: > 
    This is the first line of test #4 \U0001F600.
    This is the second line of test #4.
    This is the third line of test #4.  
````

After processing this YML file with ImmosquareYaml.clean, reserved keys such as yes and no are preserved, emojis are correctly interpreted, unnecessary quotes are removed, and multiline texts are formatted consistently.

````YML
en:
  demo: demo
  demo2:
    demo2-1:
      demo2-1-1: hello
      demo2-1-2: null
      demo2-1-3: John Doe
  demo3:
    "1": "task #1"
    "2": "task #2"
    "3": "task #2"
  description1: |-
    This is the first line of test #1 😀.
    This is the second line of test#1.
    This is the third line of test.#1
  description2: |
    This is the first line of test #2 😀.
    This is the second line of test #2.
    This is the third line of test #2.
  description3: |4-
      This is the first line of test #3 😀.
      This is the second line of test #3.
      This is the third line of test #3.
  description4: |
    This is the first line of test #4 😀. This is the second line of test #4. This is the third line of test #4.
  emoji: "Here's an emoji: 😀"
  "no": Neither is this
  some_special_characters:
    special1: "-hyphen"
    special2: "*asterisk"
    special3: "%percent"
    special4: ",comma"
    special5: "!exclamation"
    special6: "?question_mark"
    special7: "&ampersand"
    special8: "#hash"
    special9: "@at"
  "yes": This is not a boolean
````



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


### Translate YAML Files

Leveraging the growing prowess of AI tools, ImmosquareYaml has branched out to encompass translation features. The translation module utilizes OpenAI's API to translate YML files.

#### Configuration

Before using the translation feature, ensure you've set up your OpenAI API key and have chosen the OpenAI model you'd like to use. We have to add a initilizer in your Rails App

```ruby
## Available models:
## https://platform.openai.com/docs/models/
## gpt-3.5-turbo
## gpt-3.5-turbo-16k
## gpt-4
## gpt-4-32k
ImmosquareYaml.config do |config|
  config.openai_api_key = ENV.fetch("openai_api_key", nil)
  config.openai_model   = "gpt-4"
end
```

### Translation

The primary method provided by the translation module is `translate`, which takes the file path, target locale, and other options to translate the YML file.

```ruby
ImmosquareYaml::Translate.translate('path/to/your/file.yml', 'fr')
```

### Rake Tasks

Two rake tasks have been included to ease YML file management in a Rails application:

1. **Translation**: Translates translation files within your Rails application. To use this task:

```bash
rake immosquare_yaml:translate SOURCE_LOCALE=fr
```

2. **Cleaning**: Cleans translation files within your Rails application. To use this task:

```bash
rake immosquare_yaml:clean
```



## Contributing

Contributions are welcome! Please open an issue or submit a pull request on our [GitHub repository](https://github.com/IMMOSQUARE/immosquare-yaml).

## License

This gem is available under the terms of the [MIT License](https://opensource.org/licenses/MIT).
