module Envcat
  class Format
    class UnknownFormatIdError < Exception; end

    class MalformedInputError < Exception; end

    class InvalidModeError < Exception; end

    DEFAULT  = "json"
    REGISTRY = {} of String => Formatter.class

    def self.[](format_id : String)
      raise UnknownFormatIdError.new(format_id) unless REGISTRY.has_key?(format_id)
      REGISTRY[format_id]
    end

    def self.keys
      REGISTRY.keys
    end

    def self.has_format?(format_id)
      REGISTRY.has_key? format_id
    end
  end
end

module Envcat
  abstract class Format::Formatter
    module ClassMethods
      abstract def description : String
      abstract def from_string(value : String)
    end

    def initialize(@io : IO, @io_in : IO)
    end

    abstract def write(env : Env)

    macro inherited
      extend ClassMethods
      Format::REGISTRY[self.name.split("::").last.underscore.downcase] = self
    end
  end
end
