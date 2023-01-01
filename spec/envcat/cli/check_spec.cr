require "../../spec_helper"
require "../../../src/envcat/cli"

describe Envcat::Cli do
  describe "-c FOO" do
    it "fails if FOO is undefined" do
      expect_output(nil, /FOO must be defined/) { |o, e, i|
        expect_raises(Exit, "1") {
          ENV.delete("FOO")
          Envcat::Cli.invoke(%w[-c FOO], o, e, i)
        }
      }
    end

    it "succeeds if FOO is defined" do
      expect_output(nil, /^$/) { |o, e, i|
        ENV["FOO"] = "bar"
        Envcat::Cli.invoke(%w[-c FOO], o, e, i)
      }
    end
  end

  describe "-c FOO:gte:1" do
    it "fails if FOO is undefined" do
      expect_output(nil, /FOO must be >= 1/) { |o, e, i|
        expect_raises(Exit, "1") {
          ENV.delete("FOO")
          Envcat::Cli.invoke(%w[-c FOO:gte:1], o, e, i)
        }
      }
    end

    it "fails if FOO is < 1" do
      expect_output(nil, /FOO must be >= 1/) { |o, e, i|
        expect_raises(Exit, "1") {
          ENV["FOO"] = "0.5"
          Envcat::Cli.invoke(%w[-c FOO:gte:1], o, e, i)
        }
      }
    end

    it "succeeds if FOO is >= 1" do
      expect_output(nil, /^$/) { |o, e, i|
        ENV["FOO"] = "1"
        Envcat::Cli.invoke(%w[-c FOO:gte:1], o, e, i)
      }

      expect_output(nil, /^$/) { |o, e, i|
        ENV["FOO"] = "1.1"
        Envcat::Cli.invoke(%w[-c FOO:gte:1], o, e, i)
      }

      expect_output(nil, /^$/) { |o, e, i|
        ENV["FOO"] = "2"
        Envcat::Cli.invoke(%w[-c FOO:gte:1], o, e, i)
      }
    end
  end

  describe "-c FOO:?gte:1" do
    it "fails if FOO is < 1" do
      expect_output(nil, /FOO must be >= 1/) { |o, e, i|
        expect_raises(Exit, "1") {
          ENV["FOO"] = "0.5"
          Envcat::Cli.invoke(%w[-c FOO:?gte:1], o, e, i)
        }
      }
    end

    it "succeeds if FOO is undefined" do
      expect_output(/^$/, /^$/) { |o, e, i|
        ENV.delete("FOO")
        Envcat::Cli.invoke(%w[-c FOO:?gte:1], o, e, i)
      }
    end

    it "succeeds if FOO is >= 1" do
      expect_output(/^$/, /^$/) { |o, e, i|
        ENV["FOO"] = "1"
        Envcat::Cli.invoke(%w[-c FOO:?gte:1], o, e, i)
      }

      expect_output(/^$/, /^$/) { |o, e, i|
        ENV["FOO"] = "1.1"
        Envcat::Cli.invoke(%w[-c FOO:?gte:1], o, e, i)
      }

      expect_output(/^$/, /^$/) { |o, e, i|
        ENV["FOO"] = "2"
        Envcat::Cli.invoke(%w[-c FOO:?gte:1], o, e, i)
      }
    end
  end

  describe "-f json -c FOO" do
    it "applies checks before invoking a formatter" do
      expect_output(/^$/, /FOO must be defined/) { |o, e, i|
        expect_raises(Exit, "1") {
          ENV.delete("FOO")
          Envcat::Cli.invoke(%w[-c FOO], o, e, i)
        }
      }
    end
  end
end
