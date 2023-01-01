require "../format"

require "json"
require "base64"
require "compress/gzip"

module Envcat
  class Format::ETF < Format::Formatter
    def self.description : String
      "Envcat Transport Format"
    end

    def write(env : Env)
      return if env.empty?

      payload = IO::Memory.new(env.to_json)
      zipped = IO::Memory.new
      Compress::Gzip::Writer.open(zipped, level: Compress::Deflate::BEST_COMPRESSION) do |gzip|
        IO.copy(payload, gzip)
      end

      @io.puts Base64.urlsafe_encode(zipped.to_s, padding: false)
    end

    def self.from_string(value : String)
      payload = IO::Memory.new(Base64.decode_string(value))
      unzipped = IO::Memory.new
      Compress::Gzip::Reader.open(payload) do |gzip|
        IO.copy(gzip, unzipped)
      end

      unzipped.rewind
      Hash(String, String).from_json(unzipped)
    rescue ex : ::JSON::ParseException | Compress::Gzip::Error | IO::Error | Base64::Error
      raise Format::MalformedInputError.new(cause: ex.is_a?(IO::EOFError) ? nil : ex)
    end
  end
end
