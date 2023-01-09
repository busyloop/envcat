require "../format"
require "crinja"

# 🐒
class Crinja::Undefined
  class_property strict = false
  class_property tagged = [] of String

  def to_s(io)
    raise Envcat::Format::J2::UndefinedVariableError.new(@@tagged.last) if @@strict
  end
end

# 🍌
class Crinja::Util::ScopeMap(K, V)
  def [](key : K)
    val = previous_def
    Crinja::Undefined.tagged << key if parent.nil? && Crinja::Undefined.strict && val.undefined?
    val
  end
end

module Envcat
  class Format::J2 < Format::Formatter
    class UndefinedVariableError < Exception; end

    @@strict = true

    def self.description : String
      "Render j2 template from stdin (aborts with code 5 if template references an undefined var)"
    end

    def self.from_string(value : String)
      raise InvalidModeError.new "can not be used as input format"
    end

    def write(env)
      Crinja::Undefined.strict = @@strict

      crinja = Crinja.new(Crinja::Config.new(keep_trailing_newline: true))

      crinja.filters["split"] = Crinja.filter({on: nil}) { target.to_s.split(arguments["on"].to_s) }
      crinja.filters["b64encode"] = Crinja.filter { Base64.strict_encode(target.to_s) }
      crinja.filters["b64encode_urlsafe"] = Crinja.filter { Base64.urlsafe_encode(target.to_s) }
      crinja.filters["b64decode"] = Crinja.filter { Base64.decode_string(target.to_s) }

      buf = IO::Memory.new(16384)
      IO.copy(@io_in, buf)
      crinja.from_string(buf.to_s).render(@io, env.as(Envcat::Env))
    end
  end
end
