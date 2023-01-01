require "../format"
require "json"

module Envcat
  class Format::Kv < Format::Formatter
    @@prefix : String?

    def self.description : String
      "Shell format"
    end

    def self.from_string(value : String)
      raise InvalidModeError.new "can not be used as input format"
    end

    def write(env)
      env.each do |k, v|
        @io.print @@prefix if @@prefix
        @io.print k
        @io.print '='
        @io.puts Process.quote_posix(v)
      end
    end
  end
end
