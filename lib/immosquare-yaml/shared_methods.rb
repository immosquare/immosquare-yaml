module ImmosquareYaml
  module SharedMethods
    INDENT_SIZE         = 2
    NOTHING             = "".freeze
    SPACE               = " ".freeze
    NEWLINE             = "\n".freeze
    SIMPLE_QUOTE        = "'".freeze
    DOUBLE_QUOTE        = '"'.freeze
    DOUBLE_SIMPLE_QUOTE = "''".freeze
    CUSTOM_SEPARATOR    = "_#_#_".freeze
    WEIRD_QUOTES_REGEX  = /‘|’|“|”|‛|‚|„|‟|#{Regexp.quote(DOUBLE_SIMPLE_QUOTE)}/
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
  end
end
