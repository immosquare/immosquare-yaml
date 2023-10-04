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

      def strip_recursive(data)
        if data.is_a?(Array)
          data.map {|item| strip_recursive(item) }
        else
          data.strip
        end
      end

      def array_to_hash(data)
        if data.is_a?(Array)
          # Check if it's a simple key-value array
          if data.all? {|item| item.is_a?(String) } && data.none? {|item| item.include?(":") }
            data.size == 1 ? data.join : data
          elsif data.all? {|item| item.is_a?(String) }
            hash = {}
            data.each do |item|
              key, value = item.split(": ", 2)
              hash[key.chomp(":")] = value.nil? ? nil : (value.empty? ? nil : value)
            end
            hash
          # If the array contains mixed strings and arrays
          elsif data.any? {|item| item.is_a?(Array) } && data.any? {|item| item.is_a?(String) }
            hash = {}
            data.each_with_index do |item, index|
              if item.is_a?(String) && data[index + 1].is_a?(Array)
                key, = item.split(": ", 2)
                hash[key.chomp(":")] = array_to_hash(data[index + 1])
              elsif item.is_a?(String)
                key, value = item.split(": ", 2)
                hash[key.chomp(":")] = value.nil? ? nil : (value.empty? ? nil : value)
              end
            end
            hash
          # If the array contains only arrays
          elsif data.all? {|item| item.is_a?(Array) }
            data.map {|item| array_to_hash(item) }
          end
        elsif data.is_a?(String) && data.include?(":")
          key, value = data.split(": ", 2)
          {key.chomp(":") => value || nil}
        else
          data
        end
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
          sublist_start = group.index {|line| line.lstrip.start_with?("-") }

          if sublist_start
            pre_sublist = group[0...sublist_start]
            sublist     = clean_inlist_data(normalize_indentation(group[sublist_start..]))
            pre_sublist + [sublist]
          else
            group
          end
        end
      end

      lines = File.readlines("spec/fixtures/test2.yml")

      tata = clean_inlist_data(normalize_indentation(lines))
      tata = strip_recursive(tata)
      tata = array_to_hash(tata)
      puts YAML.load_file("spec/fixtures/test2.yml").inspect
      puts tata.inspect
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
