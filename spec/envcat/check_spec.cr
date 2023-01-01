require "../spec_helper"
require "../../src/envcat/check"

{% for case_path in `find fixtures/check/cases -type f`.lines.map(&.chomp).map(&.split("_")[0..-2].join("_")).sort.uniq %}
  \{% for var in `cat {{case_path.id}}_fail`.lines.map(&.chomp).map(&.split(" ")) %}
     {% case_id = case_path.split("/").last.split("_").first %}
      describe Envcat::Check do
        describe "#invalid?" do
          it "fails for {{case_path.id}}_fail: {{case_id.id}} #{\{{var.join(":")}}}" do
              Envcat::Check.invalid?({ "v" => \{{var[0]}} }, "v", {{case_id}}, \{{var[1..-1]}} of String).should be_a String
          rescue Envcat::Check::ArgumentError
            # Testcase failed successfully
          end
        end
      end
    \{% end %}

    \{% for var in `cat {{case_path.id}}_pass`.lines.map(&.chomp).map(&.split(" ")) %}
      describe Envcat::Check do
        describe "#invalid?" do
          it "passes for {{case_path.id}}_pass: {{case_id.id}} #{\{{var.join(":")}}}" do
            Envcat::Check.invalid?({ "v" => \{{var[0]}} }, "v", {{case_id}}, \{{var[1..-1]}} of String).should eq false
          end
        end
      end
  \{% end %}
{% end %}
