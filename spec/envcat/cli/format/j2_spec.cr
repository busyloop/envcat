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
          Envcat::Cli.invoke(%w[-f j2 FOO BAR], o, e, i)
        }
      }
    end

    it "fails cleanly on 'empty expression' template error" do
      tpl = "{{}}"
      expect_output(/^$/, /^Malformed template:/, tpl) { |o, e, i|
        expect_raises(Exit, "3") {
          Envcat::Cli.invoke(%w[-f j2], o, e, i)
        }
      }
    end

    it "fails if any referenced var is undefined" do
      tpl = "{{FOO}} {{BAR}}"
      expect_output(/^$/, /Undefined variable: BAR/, tpl) { |o, e, i|
        expect_raises(Exit, "5") {
          ENV["FOO"] = "1"
          ENV.delete("BAR")
          Envcat::Cli.invoke(%w[-f j2 FOO BAR], o, e, i)
        }
      }
    end

    it "fails and reports the first undefined var when any is undefined" do
      tpl = "{{FOO}} {{BAR}} {{BATZ}}"
      expect_output(/^$/, /Undefined variable: BAR/, tpl) { |o, e, i|
        expect_raises(Exit, "5") {
          ENV["FOO"] = "1"
          ENV["BAR"] = "2"
          ENV["BATZ"] = "3"
          Envcat::Cli.invoke(%w[-f j2 FOO], o, e, i)
        }
      }

      expect_output(/^$/, /Undefined variable: FOO/, tpl) { |o, e, i|
        expect_raises(Exit, "5") {
          ENV["FOO"] = "1"
          ENV["BAR"] = "2"
          ENV["BATZ"] = "3"
          Envcat::Cli.invoke(%w[-f j2 BAR], o, e, i)
        }
      }

      expect_output(/^$/, /Undefined variable: FOO/, tpl) { |o, e, i|
        expect_raises(Exit, "5") {
          ENV["FOO"] = "1"
          ENV["BAR"] = "2"
          ENV["BATZ"] = "3"
          Envcat::Cli.invoke(%w[-f j2 BATZ], o, e, i)
        }
      }

      expect_output(/^$/, /Undefined variable: BATZ/, tpl) { |o, e, i|
        expect_raises(Exit, "5") {
          ENV["FOO"] = "1"
          ENV["BAR"] = "2"
          ENV["BATZ"] = "3"
          Envcat::Cli.invoke(%w[-f j2 FOO BAR], o, e, i)
        }
      }
      expect_output(/^$/, /Undefined variable: BAR/, tpl) { |o, e, i|
        expect_raises(Exit, "5") {
          ENV["FOO"] = "1"
          ENV["BAR"] = "2"
          ENV["BATZ"] = "3"
          Envcat::Cli.invoke(%w[-f j2 FOO BATZ], o, e, i)
        }
      }

      expect_output(/^$/, /Undefined variable: FOO/, tpl) { |o, e, i|
        expect_raises(Exit, "5") {
          ENV["FOO"] = "1"
          ENV["BAR"] = "2"
          ENV["BATZ"] = "3"
          Envcat::Cli.invoke(%w[-f j2 BATZ BAR], o, e, i)
        }
      }
    end

    it "renders to stdout if all referenced vars have a value or a default" do
      tpl = "{{FOO}} {{BAR | default('2')}}"
      expect_output(/^1 2$/, /^$/, tpl) { |o, e, i|
        ENV["FOO"] = "1"
        ENV.delete("BAR")
        Envcat::Cli.invoke(%w[-f j2 FOO BAR], o, e, i)
      }
    end

    it "renders to stdout if referenced vars are made available with wildcard" do
      tpl = "{{FOO}} {{BAR | default('2')}}"
      expect_output(/^1 2$/, /^$/, tpl) { |o, e, i|
        ENV["FOO"] = "1"
        ENV.delete("BAR")
        Envcat::Cli.invoke(%w[-f j2 *], o, e, i)
      }
    end
  end

  describe "-f json -c FOO BAR" do
    it "applies checks before invoking a formatter" do
      tpl = "{{FOO} "
      expect_output(nil, /FOO must be defined/, tpl) { |o, e, i|
        expect_raises(Exit, "1") {
          ENV.delete("FOO")
          Envcat::Cli.invoke(%w[-c FOO], o, e, i)
        }
      }
    end
  end
end
