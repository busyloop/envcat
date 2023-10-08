require "../../spec_helper"
require "../../../src/envcat/cli"
require "digest/sha256"

describe Envcat::Cli do
  describe "-i json:fixtures/input/test.json -s AGE=42" do
    it "overwrites value from json" do
      expect_output(nil, nil) { |o, e, i|
        Envcat::Cli.invoke(%w[-f kv -i json:fixtures/input/test.json -s AGE=42 AGE], o, e, i)
        o.to_s.should eq("AGE=42\n")
      }
    end
  end

  describe "-s AGE=42 -i json:fixtures/input/test.json" do
    it "overwrites value from json" do
      expect_output(nil, nil) { |o, e, i|
        Envcat::Cli.invoke(%w[-f kv -s AGE=42 -i json:fixtures/input/test.json AGE], o, e, i)
        o.to_s.should eq("AGE=42\n")
      }
    end
  end
end
