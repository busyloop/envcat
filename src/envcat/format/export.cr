require "./kv"

require "json"

module Envcat
  class Format::Export < Format::Kv
    @@prefix = "export "

    def self.description : String
      "Shell export format"
    end
  end
end
