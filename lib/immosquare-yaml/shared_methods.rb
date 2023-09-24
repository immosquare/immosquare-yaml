module ImmosquareYaml
  module SharedMethods
    INDENT_SIZE         = 2
    NOTHING             = "".freeze
    SPACE               = " ".freeze
    NEWLINE             = "\n".freeze
    SIMPLE_QUOTE        = "'".freeze
    DOUBLE_QUOTE        = '"'.freeze
    DOUBLE_SIMPLE_QUOTE = "''".freeze
    WEIRD_QUOTES_REGEX  = /‘|’|“|”|‛|‚|„|‟|#{Regexp.quote(DOUBLE_SIMPLE_QUOTE)}/.freeze
    YML_SPECIAL_CHARS   = ["-", "`", "{", "}", "|", "[", "]", ">", ":", "\"", "'", "*", "=", "%", ",", "!", "?", "&", "#", "@"].freeze
    RESERVED_KEYS       = [
      "yes", "no", "on", "off", "true", "false",
      "Yes", "No", "On", "Off", "True", "False",
      "YES", "NO", "ON", "OFF", "TRUE", "FALSE"
    ].freeze

    
    ##============================================================##
    ## Deep transform values resursively
    ##============================================================##
    def deep_transform_values(hash, &block)
      hash.transform_values do |value|
        if value.is_a?(Hash)
          deep_transform_values(value, &block)
        else
          block.call(value)
        end
      end
    end

    ##============================================================##
    ## sort_by_key Function
    ## Purpose: Sort a hash by its keys, optionally recursively, with 
    ## case-insensitive comparison and stripping of double quotes.
    ## ============================================================ #
    def sort_by_key(hash, recursive = false, &block)
      block ||= proc {|a, b| a.to_s.downcase.gsub("\"", "") <=> b.to_s.downcase.gsub("\"", "") }
      hash.keys.sort(&block).each_with_object({}) do |key, seed|
        seed[key] = hash[key]
        seed[key] = sort_by_key(seed[key], true, &block) if recursive && seed[key].is_a?(Hash)
      end
    end
  end
end