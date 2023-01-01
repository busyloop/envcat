require "../../spec_helper"
require "../../../src/envcat/cli"

describe Envcat::Cli do
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
