require "../format"

require "json"

module Envcat
  class Format::JSON < Format::Formatter
    def self.description : String
      "JSON format"
    end

    def self.from_string(value : String)
      raise InvalidModeError.new "can not be used as input format"
    end

    def write(env : Env)
      return if env.empty?
      env.to_json(@io)
      @io.puts
    end
  end
end
