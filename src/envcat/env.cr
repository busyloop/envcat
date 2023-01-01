module Envcat
  class Env
    @kv = {} of String => String

    forward_missing_to @kv

    def initialize(env, globs : Array(String) = [] of String)
      import(env, globs)
    end

    def import(env, globs)
      globs.each do |glob|
        glob, format_id = glob.split(":", 2) rescue [glob, nil]
        env.keys.each do |key|
          if File.match?(glob, key)
            if format_id
              Format[format_id].from_string(env[key]).each do |k, v|
                env[k] = v
              end
            else
              @kv[key] = env[key]
            end
          end
        rescue ex : Format::MalformedInputError
          raise Format::MalformedInputError.new("#{key} is not in #{format_id} format", cause: ex.cause)
        rescue ex : Format::InvalidModeError
          raise Format::InvalidModeError.new("#{key} #{ex.message}", cause: ex.cause)
        end
      end
    end
  end
end
