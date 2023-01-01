require "../../spec_helper"
require "../../../src/envcat/cli"

describe Envcat::Cli do
  describe "-f export FOO" do
    it "reports I/O error with exit code 7" do
      expect_output(/^$/, /^Error: Closed stream\n$/) { |o, e, i|
        o.close
        expect_raises(Exit, "7") {
          ENV["FOO"] = "1"
          Envcat::Cli.invoke(%w[-f export FOO], o, e, i)
        }
      }
    end
  end
end
