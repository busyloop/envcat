require "../../spec_helper"
require "../../../src/envcat/cli"
require "digest/sha256"

describe Envcat::Cli do
  {% for fmt in %w[json yaml toml] %}
  describe "-i {{fmt.id}}:fixtures/input/test.{{fmt.id}}" do
    it "parses and normalizes {{fmt.id}}" do
      expect_output(nil, nil) { |o, e, i|
        Envcat::Cli.invoke(%w[-f yaml -i {{fmt.id}}:fixtures/input/test.{{fmt.id}} *], o, e, i)
        fixture = YAML.parse(File.read("fixtures/input/test_normalized.yaml"))
        YAML.parse(o.to_s).should eq(fixture)
      }
    end
  end

  describe "-i {{fmt.id}}:fixtures/input/test.invalid" do
    it "prints error and exits with code 11 if parsing fails" do
      expect_output(nil, /Malformed input.*is not valid {{fmt.id.upcase}}/) { |o, e, i|
        expect_raises(Exit, "11") {
          Envcat::Cli.invoke(%w[-f yaml -i {{fmt.id}}:fixtures/input/test.invalid *], o, e, i)
        }
      }
    end
  end

  describe "-i {{fmt.id}}:fixtures/input/test.notfound" do
    it "prints error and exits with code 7 if input file doesn't exist" do
      expect_output(nil, /No such file or directory/) { |o, e, i|
        expect_raises(Exit, "7") {
          Envcat::Cli.invoke(%w[-f yaml -i {{fmt.id}}:fixtures/input/test.notfound *], o, e, i)
        }
      }
    end
  end
  {% end %}

  {% for fmt in %w[env- derp] %}
  describe "-i {{fmt.id}}" do
    it "prints error and exits with code 3 if argument to -i is invalid" do
      expect_output(nil, /Unknown input type/) { |o, e, i|
        expect_raises(Exit, "3") {
          Envcat::Cli.invoke(%w[-i {{fmt.id}} *], o, e, i)
        }
      }
    end
  end
  {% end %}

  {% for fmt in %w[yaml yaml: json json: toml toml:] %}
  describe "-i {{fmt.id}}" do
    it "prints error and exits with code 3 if argument to -i misses path" do
      expect_output(nil, /Path is required/) { |o, e, i|
        expect_raises(Exit, "3") {
          Envcat::Cli.invoke(%w[-i {{fmt.id}} *], o, e, i)
        }
      }
    end
  end
  {% end %}
end
