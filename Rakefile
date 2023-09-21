require "rake"
require "immosquare-yaml"
require_relative "spec/fixtures/sample"

namespace :immosquare_yaml do
  desc "Clean the sample YAML file"
  task :clean_sample do
    ImmosquareYaml.clean("spec/fixtures/sample.en.yml")
  end

  task :parse_sample do
    data = ImmosquareYaml.parse("spec/fixtures/sample.en.yml")
    puts data.inspect
  end

  task :dump_sample do
    yaml = ImmosquareYaml.dump(YML_HASH)
    puts yaml
  end
end
