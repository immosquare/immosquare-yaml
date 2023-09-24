module ImmosquareYaml
  class Configuration

    attr_accessor :openai_api_key

    def initialize
      @openai_api_key = nil
    end

  end
end