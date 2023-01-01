require "../format"

require "yaml"

module Envcat
  class Format::YAML < Format::Formatter
    def self.description : String
      "YAML format"
    end

    def self.from_string(value : String)
      raise InvalidModeError.new "can not be used as input format"
    end

    def write(env)
      return if env.empty?
      env.to_yaml(@io)
    end
  end
end
