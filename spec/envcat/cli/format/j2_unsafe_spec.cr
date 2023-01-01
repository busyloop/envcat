require "../../../spec_helper"
require "../../../../src/envcat/cli"

describe Envcat::Cli do
  describe "-f j2 FOO BAR" do
    it "fails if template is malformed" do
      tpl = "{{FOO} "
      expect_output(/^$/, /^Malformed template:/, tpl) { |o, e, i|
        expect_raises(Exit, "3") {
          ENV["FOO"] = "1"
          ENV.delete("BAR")
          Envcat::Cli.invoke(%w[-f j2_unsafe FOO BAR], o, e, i)
        }
      }
    end

    it "renders undefined vars as empty string" do
      tpl = "{{FOO}} {{BAR}}"
      expect_output(/^ 2$/, /^$/, tpl) { |o, e, i|
        ENV.delete("FOO")
        ENV["BAR"] = "2"
        Envcat::Cli.invoke(%w[-f j2_unsafe FOO BAR], o, e, i)
      }
    end
  end
end
