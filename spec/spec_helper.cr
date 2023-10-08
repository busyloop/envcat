::BUILD_ENV = :spec

require "../src/envcat"

ENV.clear

class Exit < Exception; end

macro exit(code)
  {% if @type.name.starts_with? "Envcat" %}
    raise Exit.new(({{code}}).to_s)
  {% end %}
  Process.exit {{code}}
end

require "spec"

def expect_output(stdout_re : Regex? = nil, stderr_re : Regex? = nil, stdin_data = "", &block : (IO, IO, IO) ->)
  i = IO::Memory.new(stdin_data)
  o = IO::Memory.new
  e = IO::Memory.new
  block.call(o, e, i)

  o.to_s.should match(stdout_re) if stdout_re
  e.to_s.should match(stderr_re) if stderr_re
end
