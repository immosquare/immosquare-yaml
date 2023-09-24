require "json"
require "rake"
require "immosquare-yaml"

namespace :immosquare_yaml do
  desc "Clean, parse, dump the sample files"

  ##=============================================================##
  ## Load config keys from config_dev.yml
  ##=============================================================##
  def load_config
    path = "#{File.dirname(__FILE__)}/config_dev.yml"
    abort("Error: config_dev.yml not found") if !File.exist?(path)
    
    ##=============================================================##
    ## Load config keys from config_dev.yml
    ##=============================================================##
    dev_config = ImmosquareYaml.parse(path)
    abort("Error config_dev.yml is empty") if dev_config.nil?

    ImmosquareYaml.config do |config|
      config.openai_api_key = dev_config["openai_api_key"]
    end
  end
  
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


  task :translate_sample do
    load_config
    input  = "spec/fixtures/sample.en.yml"
    ImmosquareYaml::Translate.translate(input, :locale => "fr", :clean_original => false)
  end
end
