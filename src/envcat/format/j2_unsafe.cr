require "./j2"

module Envcat
  class Format::J2Unsafe < Format::J2
    @@strict = false

    def self.description : String
      "Render j2 template from stdin (renders undefined vars as empty string)"
    end
  end
end
