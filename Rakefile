require "json"
require "rake"
require "immosquare-yaml"

namespace :immosquare_yaml do
  desc "Clean, parse, dump, translate the sample files"
  namespace :sample do
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



    task :toto do
      def normalize_indentation(lines)
        initial_indentation = lines.first.match(/^(\s*)/)[1].length
        lines.map {|line| line[initial_indentation..] }
      end

      def clean_inlist_data(lines)
        normalized_lines  = normalize_indentation(lines)
        result            = []
        last_indent       = nil
        current_indent    = nil
        indent_size       = 2

        normalized_lines.each do |line|
          last_indent    = current_indent
          current_indent = indent_level = line[/\A */].size

          if line.start_with?("-")
            stripped_line = line[1..].strip
            key, value    = stripped_line.split(":", 2)
            result << {key => value}
          elsif current_indent - indent_size == last_indent
            stripped_line = line.strip
            key, value    = stripped_line.split(":", 2)
            result.last.merge!({key => value})
          elsif current_indent - (2 * indent_size) == last_indent
            last                  = result.last
            last[last.keys.first] = clean_inlist_data([line])
          else
            puts(line)
          end
        end
        result
      end

      toto = ["    - marque: Toyota\n", "      modèle: Corolla\n", "    - marque: Honda\n", "      modèle: null\n", "    - toto:\n", "        - tata: ici\n", "          pipi: la\n"]
      puts clean_inlist_data(toto).inspect
    end




    ##=============================================================##
    ## Parse the sample YAML file
    ##=============================================================##
    desc "Parse the sample files"
    task :parse do
      data = ImmosquareYaml.parse("spec/fixtures/sample.en.yml", :sort => false)
      puts JSON.pretty_generate(data)
      File.write("spec/fixtures/sample.json", JSON.pretty_generate(data))
    end

    ##=============================================================##
    ## Clean the sample YAML file
    ##=============================================================##
    desc "Clean the sample files"
    task :clean do
      input  = "spec/fixtures/sample.en.yml"
      output = "spec/output/sample_cleaned.en.yml"
      ImmosquareYaml.clean(input, :output => output)
    end


    ##=============================================================##
    ## Dump the sample YAML file
    ##=============================================================##
    desc "Dump the sample files"
    task :dump do
      data = JSON.parse(File.read("spec/fixtures/sample.json"))
      yaml = ImmosquareYaml.dump(data)
      puts yaml
    end


    ##=============================================================##
    ## Translate the sample YAML file
    ##=============================================================##
    desc "Translate the sample files"
    task :translate do
      load_config
      input = "spec/output/sample_cleaned.en.yml"
      ImmosquareYaml::Translate.translate(input, "fr")
    end
  end
end
