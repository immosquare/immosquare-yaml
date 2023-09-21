Gem::Specification.new do |spec|
  spec.name          = "immosquare-yaml"
  spec.version       = "0.1.0"
  spec.authors       = ["IMMO SQUARE"]
  spec.email         = ["jules@immosquare.com"]

  spec.summary       = "A YAML parser tailored for real estate solutions."
  spec.description   = "IMMOSQUARE-YAML is a lightweight and efficient YAML parser designed to facilitate the handling of real estate data in YAML format, offering streamlined processes and a simplified user experience."
  
  spec.homepage      = "https://github.com/IMMOSQUARE/immosquare-yaml"
  
  spec.files         = Dir["lib/**/*"]
  spec.bindir        = "exe"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")
  
  spec.add_dependency("iso-639", "> 0.2.5")


end