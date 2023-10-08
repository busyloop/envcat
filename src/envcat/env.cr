require "json"
require "yaml"
require "toml"

module Envcat
  class ParseException < Exception; end

  class Env
    @@source_cache = {} of String => String
    @kv = {} of String => String

    forward_missing_to @kv

    def initialize(@globs : Array(String) = [] of String)
    end

    def merge(hash, globs = @globs)
      globs.each do |glob|
        glob, format_id = glob.split(":", 2) rescue [glob, nil]
        hash.keys.each do |key|
          if File.match?(glob, key)
            if format_id
              Format[format_id].from_string(hash[key]).each do |k, v|
                hash[k] = v
              end
            else
              @kv[key] = hash[key]
            end
          end
        rescue ex : Format::MalformedInputError
          raise Format::MalformedInputError.new("#{key} is not in #{format_id} format", cause: ex.cause)
        rescue ex : Format::InvalidModeError
          raise Format::InvalidModeError.new("#{key} #{ex.message}", cause: ex.cause)
        end
      end
    end

    def read_and_cache(path)
      @@source_cache[path] ||= File.read(path)
    end

    def merge_json(path)
      merge(self.class.flatten_hash(JSON.parse(read_and_cache(path)).as_h))
    rescue ex : JSON::ParseException | TypeCastError
      raise ParseException.new("#{path} is not valid JSON", cause: ex)
    end

    def merge_yaml(path)
      merge(self.class.flatten_hash(YAML.parse(read_and_cache(path)).as_h))
    rescue ex : YAML::ParseException | TypeCastError
      raise ParseException.new("#{path} is not valid YAML", cause: ex)
    end

    def merge_toml(path)
      toml = TOML.parse(read_and_cache(path))
      toml.each do |k, v|
        if value = v.as_h?
          merge(self.class.flatten_hash(value, [k]))
        else
          hash = {} of String => TOML::Any
          hash[k] = v
          merge(self.class.flatten_hash(hash))
        end
      end
    rescue ex : TOML::ParseException | TypeCastError
      raise ParseException.new("#{path} is not valid TOML", cause: ex)
    end

    def self.flatten_hash(hash, prefix = [] of String, output = {} of String => String, &keymaker : Array(String) -> String)
      hash.each do |k, v|
        path = prefix + [k.to_s]
        if child = v.as_h?
          flatten_hash(child, path, output, &keymaker)
        elsif child = v.as_a?
          flatten_array(child, path, output, &keymaker)
        else
          output[keymaker.call(path)] = v.to_s
        end
      end
      output
    end

    def self.flatten_array(array, prefix = [] of String, output = {} of String => String, &keymaker : Array(String) -> String)
      array.each_with_index do |v, i|
        path = prefix + [i.to_s]
        if child = v.as_h?
          flatten_hash(child, path, output, &keymaker)
        elsif child = v.as_a?
          flatten_array(child, path, output, &keymaker)
        else
          output[keymaker.call(path)] = v.to_s
        end
      end
      output
    end

    def self.flatten_hash(hash, prefix = [] of String, output = {} of String => String)
      flatten_hash(hash, prefix, output) do |path|
        path.map(&.upcase).map(&.gsub(/[^A-Z0-9]/, '_')).join('_')
      end
    end
  end
end
