module ImmosquareYaml
  
  module Translate
    class << self

      def translate(input, options = {})
        ##=============================================================##
        ## Load config keys from config_dev.yml
        ##=============================================================##
        openai_api_key = ImmosquareYaml.configuration.openai_api_key
        abort("Error: openai_api_key not found in config_dev.yml") if openai_api_key.nil? 

        ##=============================================================##
        ## Load the input file
        ##=============================================================##
        puts(input)
      end

    end
  end
end