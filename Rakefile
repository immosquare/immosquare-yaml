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
        return lines.map {|l| l[1..].strip } if lines.all? {|l| l.start_with?("-") }

        index   = -1
        results = []
        lines.each do |line|
          if line.start_with?("-")
            index += 1
            line = line[1..].lstrip
          end
          results[index] = [] if results[index].nil?
          results[index] << line
        end



        results.map do |group|
          list_index = nil
          new_lines  = nil
          group.each.with_index do |line, index|
            if line.lstrip.start_with?("-") && list_index.nil?
              list_index = index
              new_lines = normalize_indentation(group[index..]) if !list_index.nil?
            end
          end
          list_index.nil? ? group : group[0..list_index - 1] + [clean_inlist_data(new_lines)]
        end
      end

      lines = [
        "- marque: Toyota2",
        "  modèle: Corolla",
        "  hello: null",
        "- marque: Honda",
        "  modèle: null",
        "- toto:",
        "  - tata: ici",
        "    pipi:",
        "      - hello",
        "      - barbie:"
      ]

      tata = clean_inlist_data(normalize_indentation(lines))
      puts tata.inspect
      # puts array_to_hash(tata).inspect
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
