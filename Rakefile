require "json"
require "rake"
require "immosquare-yaml"

namespace :immosquare_yaml do
  desc "Clean, parse, dump the sample files"
  namespace :sample do
    ##=============================================================##
    ## Parse the sample YAML file
    ## rake immosquare_yaml:sample:parse
    ##=============================================================##
    desc "Parse the sample files"
    task :parse do
      data = ImmosquareYaml.parse("spec/fixtures/sample.en.yml", :sort => true)
      puts JSON.pretty_generate(data)
      File.write("spec/fixtures/sample.json", JSON.pretty_generate(data))
    end

    ##=============================================================##
    ## Clean the sample YAML file
    ## rake immosquare_yaml:sample:clean
    ##=============================================================##
    desc "Clean the sample files"
    task :clean do
      input  = "spec/fixtures/sample.en.yml"
      output = "spec/output/sample_cleaned.en.yml"
      ImmosquareYaml.clean(input, :output => output)
    end


    ##=============================================================##
    ## Dump the sample YAML file
    ## rake immosquare_yaml:sample:dump
    ##=============================================================##
    desc "Dump the sample files"
    task :dump do
      data = JSON.parse(File.read("spec/fixtures/sample.json"))
      yaml = ImmosquareYaml.dump(data)
      puts yaml
    end
  end
end
