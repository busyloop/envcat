require "json"
require "socket"
require "semantic_version"

module Envcat
  class Check
    class UnknownConstraintIdError < Exception; end

    class ConstraintViolationError < Exception; end

    class ArgumentError < Exception; end

    RX_ALNUM    = /^[a-zA-Z0-9]+$/
    RX_HEX      = /^(0x|0h)?[0-9A-F]+$/i
    RX_HEXCOLOR = /^#?([0-9A-F]{3}|[0-9A-F]{4}|[0-9A-F]{6}|[0-9A-F]{8})$/i
    RX_INT      = /^[-]?\d+$/
    RX_NUM      = /^[-]?([0-9]*[.])?[0-9]+$/
    RX_UUID     = /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/i
    RX_UFLOAT   = /^([0-9]*[.])?[0-9]+$/
    RX_UINT     = /^\d+$/

    CONSTRAINTS = {
      presence: ->(v : String?, _a : Array(String)) { v && !v.empty? || "must be defined" },
      alnum:    ->(v : String?, _a : Array(String)) { v && RX_ALNUM.match(v) || "must be alphanumeric" },
      b64:      ->(v : String?, _a : Array(String)) { v && (v.size % 4 === 0) && /^[a-zA-Z0-9+\/]+={0,2}$/ =~ v || "must be base64" },
      f:        ->(v : String?, _a : Array(String)) { v && RX_UFLOAT.match(v) || "must be an unsigned float" },
      fs:       ->(v : String?, _a : Array(String)) { v && File.exists?(v) || "must be a path to an existing file or directory" },
      fsd:      ->(v : String?, _a : Array(String)) { v && File.directory?(v) || "must be a path to an existing directory" },
      fsf:      ->(v : String?, _a : Array(String)) { v && File.file?(v) || "must be a path to an existing file" },
      gt:       ->(v : String?, a : Array(String)) { v && v.to_f > a[0].to_f || "must be > #{a[0]}" },
      gte:      ->(v : String?, a : Array(String)) { v && v.to_f >= a[0].to_f || "must be >= #{a[0]}" },
      hex:      ->(v : String?, _a : Array(String)) { v && RX_HEX.match(v) || "must be a hex number" },
      hexcol:   ->(v : String?, _a : Array(String)) { v && RX_HEXCOLOR.match(v) || "must be a hex color" },
      i:        ->(v : String?, _a : Array(String)) { v && RX_UINT.match(v) || "must be an unsigned integer" },
      ip:       ->(v : String?, _a : Array(String)) { v && Socket::IPAddress.valid?(v) || "must be an ip address" },
      ipv4:     ->(v : String?, _a : Array(String)) { v && Socket::IPAddress.valid_v4?(v) || "must be an ipv4 address" },
      ipv6:     ->(v : String?, _a : Array(String)) { v && Socket::IPAddress.valid_v6?(v) || "must be an ipv6 address" },
      json:     ->(v : String?, _a : Array(String)) { v && JSON.parse(v) || raise "" rescue "must be JSON" },
      lc:       ->(v : String?, _a : Array(String)) { v && v.downcase === v || "must be all lowercase" },
      len:      ->(v : String?, a : Array(String)) { v && v.size >= a[0].to_i && v.size <= a[1].to_i || "must be #{a[0]}-#{a[1]} characters" },
      lt:       ->(v : String?, a : Array(String)) { v && v.to_f < a[0].to_f || "must be < #{a[0]}" },
      lte:      ->(v : String?, a : Array(String)) { v && v.to_f <= a[0].to_f || "must be <= #{a[0]}" },
      n:        ->(v : String?, _a : Array(String)) { v && RX_UFLOAT.match(v) || "must be an unsigned float or integer" },
      nre:      ->(v : String?, a : Array(String)) { v && !Regex.new(a.join(":")).match(v) || "must not match PCRE regex: #{a.same?(DUMMY_ARGS) ? a[0] : a.join(":")}" },
      port:     ->(v : String?, _a : Array(String)) { v && RX_INT.match(v) && v.to_i >= 0 && v.to_i <= 65535 || "must be a port number (0-65535)" },
      re:       ->(v : String?, a : Array(String)) { v && Regex.new(a.join(":")).match(v) || "must match PCRE regex: #{a.same?(DUMMY_ARGS) ? a[0] : a.join(":")}" },
      sf:       ->(v : String?, _a : Array(String)) { v && RX_NUM.match(v) || "must be a float" },
      si:       ->(v : String?, _a : Array(String)) { v && RX_INT.match(v) || "must be an integer" },
      sn:       ->(v : String?, _a : Array(String)) { v && RX_NUM.match(v) || "must be a float or integer" },
      uc:       ->(v : String?, _a : Array(String)) { v && v.upcase === v || "must be all uppercase" },
      uuid:     ->(v : String?, _a : Array(String)) { v && RX_UUID.match(v) || "must be a UUID" },
      v:        ->(v : String?, _a : Array(String)) { v && SemanticVersion.parse(v) || raise "" rescue "must be a semantic version" },
      vgt:      ->(v : String?, a : Array(String)) { v && SemanticVersion.parse(v) > SemanticVersion.parse(a[0]) || raise "" rescue "must be a semantic version > #{a[0]}" },
      vgte:     ->(v : String?, a : Array(String)) { v && SemanticVersion.parse(v) >= SemanticVersion.parse(a[0]) || raise "" rescue "must be a semantic version >= #{a[0]}" },
      vlt:      ->(v : String?, a : Array(String)) { v && SemanticVersion.parse(v) < SemanticVersion.parse(a[0]) || raise "" rescue "must be a semantic version < #{a[0]}" },
      vlte:     ->(v : String?, a : Array(String)) { v && SemanticVersion.parse(v) <= SemanticVersion.parse(a[0]) || raise "" rescue "must be a semantic version <= #{a[0]}" },
    }

    DUMMY_ARGS        = %w[X Y ..]
    EXCLUDE_FROM_HELP = %i[presence]

    def self.invalid?(env, var_name, constraint_id, args : Array(String), permit_undefined = false)
      raise UnknownConstraintIdError.new("Unknown check type '#{constraint_id}'\nMust be one of: #{(CONSTRAINTS.keys.to_a - EXCLUDE_FROM_HELP).join(" ")}") unless CONSTRAINTS.has_key? constraint_id
      value = env[var_name]?
      return false if value.nil? && permit_undefined
      result = CONSTRAINTS[constraint_id].call(value, args)
      result.is_a?(String) ? "#{var_name} #{result}" : false
    rescue ex : ::ArgumentError
      raise Check::ArgumentError.new(ex.message, cause: ex)
    rescue ex : IndexError
      raise Check::ArgumentError.new("Argument missing", cause: ex)
    end

    def self.help_for(io, constraint_id)
      return if EXCLUDE_FROM_HELP.includes? constraint_id
      sample_error = CONSTRAINTS[constraint_id].call(nil, DUMMY_ARGS).to_s

      text = String.build do |s|
        s << "  "
        s << constraint_id
        DUMMY_ARGS.each do |x|
          next unless sample_error.includes? x
          s << ":"
          s << x
        end
        s << " " * (20 - s.bytesize)
        s << sample_error
      end

      io.puts text
    end
  end
end
