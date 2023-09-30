require_relative "lib/immosquare-yaml/version"


Gem::Specification.new do |spec|
  spec.license       = "MIT"
  spec.name          = "immosquare-yaml"
  spec.version       = ImmosquareYaml::VERSION.dup
  spec.authors       = ["IMMO SQUARE"]
  spec.email         = ["jules@immosquare.com"]

  spec.summary       = "A YAML parser optimized for translation files."
  spec.description   = "IMMOSQUARE-YAML is a specialized Ruby gem tailored primarily for parsing and dumping YML translation files, addressing challenges faced with other parsers like interpreting translation keys as booleans, multi-line strings, and more."

  
  spec.homepage      = "https://github.com/IMMOSQUARE/immosquare-yaml"
  
  spec.files         = Dir["lib/**/*"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.2")
  
  spec.add_dependency("iso-639",  "~> 0")
  spec.add_dependency("httparty", "~> 0")
  spec.add_dependency("immosquare-extensions", "~> 0")

end
