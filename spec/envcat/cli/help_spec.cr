require "../../spec_helper"
require "../../../src/envcat/cli"

describe Envcat::Cli do
  describe "--help" do
    it "prints help and exits with code 0" do
      expect_output(nil, /Usage:.*SPEC/) { |o, e, i|
        expect_raises(Exit, "0") {
          Envcat::Cli.invoke(%w[--help], o, e, i)
        }
      }
    end
  end

  describe "-h" do
    it "prints help and exits with code 0" do
      expect_output(nil, /Usage:.*SPEC/) { |o, e, i|
        expect_raises(Exit, "0") {
          Envcat::Cli.invoke(%w[-h], o, e, i)
        }
      }
    end
  end

  describe "(invalid arguments)" do
    it "prints help and exits with code 3" do
      expect_output(nil, /Usage:.*SPEC/) { |o, e, i|
        expect_raises(Exit, "3") {
          Envcat::Cli.invoke(%w[--port -x], o, e, i)
        }
      }
    end
  end

  describe "(no arguments)" do
    it "prints help and exits with code 3" do
      expect_output(nil, /Usage:.*SPEC/) { |o, e, i|
        expect_raises(Exit, "3") {
          Envcat::Cli.invoke(%w[], o, e, i)
        }
      }
    end
  end
end
