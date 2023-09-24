module ImmosquareYaml
  
  module Translate
    extend SharedMethods

    class << self

      def translate(file_path, locale_to,  options = {})
        begin
          ##=============================================================##
          ## options
          ##=============================================================##
          options = {
            :reset_translations => false
          }.merge(options)
          options[:reset_translations] = false  if ![true, false].include?(options[:reset_translations])


          ##=============================================================##
          ## Load config keys from config_dev.yml
          ##=============================================================##
          openai_api_key = ImmosquareYaml.configuration.openai_api_key
          raise("Error: openai_api_key not found in config_dev.yml") if openai_api_key.nil? 
          raise("Error: File #{file_path} not found")                if !File.exist?(file_path)
          raise("Error: locale is not a locale")                     if !locale_to.is_a?(String) || locale_to.size != 2
  
          ##============================================================##
          ## We clean the file before translation
          ##============================================================##
          ImmosquareYaml.clean(file_path)

          ##============================================================##
          ## We parse the clean input file
          ##============================================================##
          hash_from = ImmosquareYaml.parse(file_path)
          raise("#{file_path} is not a correct yml translation file") if !hash_from.is_a?(Hash) && hash_from.keys.size > 1

          ##============================================================##
          ## Check if the locale is present in the file
          ##============================================================##
          locale_from = hash_from.keys.first.to_s
          raise("Error: The destination file (#{locale_to}) is the same as the source file (#{locale_from}).")    if locale_from == locale_to
          raise("Error: Expected the source file (#{file_path}) to end with '#{locale_from}.yml' but it didn't.") if !file_path.end_with?("#{locale_from}.yml")


          ##============================================================##
          ## Prepare the output file
          ##============================================================##
          file_basename        = File.basename(file_path)
          file_dirname         = File.dirname(file_path)
          translated_file_path = "#{file_dirname}/#{file_basename.gsub("#{locale_from}.yml", "#{locale_to}.yml")}"

          ##============================================================##
          ## We create a hash with all keys from the source file
          ##============================================================##
          hash_to = {locale_to => hash_from.delete(locale_from)}

          ##============================================================##
          ## We create a array with all keys from the source file
          ##============================================================##
          array_to = translatable_array(hash_to)
          array_to = array_to.map {|k, v| [k, v, nil] }
          
          ##============================================================##
          ## If we already have a translation file for the language
          ## we get the values in it and put it in our
          ## file... You have to do well with !nil?
          ## to retrieve the values "" and " "...
          ##============================================================##
          if File.exist?(translated_file_path) && options[:reset_translations] == false
            temp_hash = ImmosquareYaml.parse(translated_file_path)
            raise("#{translated_file_path} is not a correct yml translation file") if !temp_hash.is_a?(Hash) && temp_hash.keys.size > 1

            ##============================================================##
            ## t can be nil if the key is not present in the source file
            ##============================================================##
            translatable_array(temp_hash).each do |key, value|
              t    = array_to.find {|k, _v| k == key }
              t[2] = value if !t.nil? && !value.nil?
            end
          end

          ##============================================================##
          ## Here we have to do all the translation logic...
          ## For the moment we use the OPENAI API, but we can imagine
          ## using other translation APIs in the future.
          ##============================================================##
          translated_array = translate_with_open_ai(array_to, locale_from, locale_to)

          ##============================================================##
          ## Then we have to reformat the output yml file
          ##============================================================##
          final_array = translated_array.map {|k, _from, to| [k, to] }
          final_hash  = translatable_hash(final_array)

          ##============================================================##
          ## We write the output file
          ##============================================================##
          File.write(translated_file_path, ImmosquareYaml.dump(final_hash))
        rescue StandardError => e
          puts(e.message)
          puts(e.backtrace)
          false
        end
      end


      private

      ##============================================================##
      ## To translatable hash to array
      ## opitons are :
      ## :format    => "string" or "array"
      ## :keys_only => true or false
      ## {:fr=>{"demo1"=>"demo1", "demo2"=>{"demo2-1"=>"demo2-1"}}}
      ## format = "string" and keys_only = false => [["fr.demo1", "demo1"], ["fr.demo2.demo2-1", "demo2-1"]]
      ## format = "string" and keys_only = true  => ["fr.demo1", "fr.demo2.demo2-1"]
      ## format = "array"  and keys_only = false => [[["fr", "demo1"], "demo1"], [["fr", "demo2", "demo2-1"], "demo2-1"]]
      ## format = "array"  and keys_only = true  => [["fr", "demo1"], ["fr", "demo2", "demo2-1"]]
      ## ============================================================ 
      def translatable_array(hash, key = nil, result = [], **options)
        options = {
          :format    => "string",
          :keys_only => false
        }.merge(options)
        options[:keys_only] = false    if ![true, false].include?(options[:keys_only])
        options[:format]    = "string" if !["string", "array"].include?(options[:format])


        if hash.is_a?(Hash)
          hash.each_key do |k|
            translatable_array(hash[k], "#{key}#{":" if !key.nil?}#{k}", result, **options)
          end
        else
          r2 = options[:format] == "string" ? key.split(":").join(".") : key.split(":")
          result << (options[:keys_only] ? r2 : [r2, hash])
        end
        result
        
      end

      ##============================================================##
      ## We can do the inverse of the previous function
      ##============================================================##
      def translatable_hash(array)
        data_hash = array.to_h
        final     = {}
        data_hash.each do |key, value|
          key_parts     = key.split(".")
          leaf          = key_parts.pop
          parent        = key_parts.inject(final) {|h, k| h[k] ||= {} }
          parent[leaf]  = value
        end
        final
      end      

      ##============================================================##
      ## Translate with OpenAI
      ##============================================================##
      def translate_with_open_ai(array, locale_from, locale_to)
        array.map {|key, from, to| [key, from, "#{to} TODO"] }
      end


    end
  end
end