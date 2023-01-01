require "../format"

require "yaml"

module Envcat
  class Format::None < Format::Formatter
    def self.description : String
      "No format"
    end

    def self.from_string(value : String)
      raise InvalidModeError.new "can not be used as input format"
    end

    def write(env)
      # 🦗
    end
  end
end
