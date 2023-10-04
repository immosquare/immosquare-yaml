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

      def toto(lines)
        return lines.map {|l| l[1..].strip } if lines.all? {|l| l.start_with?("-") }

        index = -1
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
          tamere = nil
          tonpere = nil
          group.each.with_index do |line, index|
            if line.lstrip.start_with?("-") && tamere.nil?
              tamere  = index
              tonpere = normalize_indentation(group[index..]) if !tamere.nil?
            end
          end
          tamere.nil? ? group : group[0..tamere - 1] + [toto(tonpere)]
        end
      end

      def array_to_hash(arr)
        hash = {}

        arr.each do |item|
          if item.is_a?(String)
            key, value = item.split(":", 2).map(&:strip) # divisez la chaîne en deux parties basées sur ':'
            value = nil if value == "null"
            hash[key] = value
          elsif item.is_a?(Array)
            item.each do |key_val|
              if key_val.is_a?(String)
                key, value = key_val.split(":", 2).map(&:strip)
                value = nil if value == "null"
                hash[key] = value
              elsif key_val.is_a?(Array)
                key, nested_arr = key_val
                hash[key.strip] = array_to_hash(nested_arr)
              end
            end
          end
        end

        hash
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
        "      - barbie:",
        "          - hello",
        "          - robot"

      ]


      tata = toto(normalize_indentation(lines))
      puts tata.inspect
      puts array_to_hash(tata).inspect
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
