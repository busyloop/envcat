module Envcat
  VERSION = {{ `grep "^version" shard.yml | cut -d ' ' -f 2`.chomp.stringify }}
end
