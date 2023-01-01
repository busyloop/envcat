require "../../../spec_helper"
require "../../../../src/envcat/cli"

describe Envcat::Cli do
  describe "-f json FOO BAR" do
    it "outputs nothing if selected vars are empty" do
      expect_output(/^$/, /^$/) { |o, e, i|
        ENV.delete("FOO")
        ENV.delete("BAR")
        Envcat::Cli.invoke(%w[-f json FOO BAR], o, e, i)
      }
    end

    it "writes json to stdout if a selected var has a value" do
      expect_output(/{"BAR":"1"}/, /^$/) { |o, e, i|
        ENV.delete("FOO")
        ENV["BAR"] = "1"
        Envcat::Cli.invoke(%w[-f json FOO BAR], o, e, i)
      }
    end
  end
end
