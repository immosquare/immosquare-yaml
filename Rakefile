require "json"
require "rake"
require "immosquare-yaml"

namespace :immosquare_yaml do
  desc "Clean, parse, dump the sample files"
  
  ##=============================================================##
  ## Clean the sample YAML file                                  
  ##=============================================================##
  task :clean_sample do
    input  = "spec/fixtures/sample.en.yml"
    output = "spec/output/sample_cleaned.en.yml"
    ImmosquareYaml.clean(input, :output => output)
  end

  ##=============================================================##
  ## Parse the sample YAML file                                  
  ##=============================================================##
  task :parse_sample do
    data = ImmosquareYaml.parse("spec/fixtures/sample.en.yml")
    File.write("spec/fixtures/sample.json", JSON.pretty_generate(data))
  end

  ##=============================================================##
  ## Dump the sample YAML file                                  
  ##=============================================================##
  task :dump_sample do
    data = JSON.parse(File.read("spec/fixtures/sample.json"))
    yaml = ImmosquareYaml.dump(data)
    puts yaml
  end
end
