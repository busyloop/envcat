#!/usr/bin/env ruby

# crystal_action.rb v1.0.0
# (c)2023 moe@busyloop.net - MIT License

require 'json'
require 'yaml'

SHARD_YML = YAML.load_file('shard.yml')

ENTRIES={}
ENTRIES['platform'] = SHARD_YML['support_matrix']['platforms']
ENTRIES['crystal'] = SHARD_YML['support_matrix']['crystal_versions'] # + %w[latest]

def product_hash(hsh)
  keys  = hsh.keys
  attrs = keys.map { |key| hsh[key] }
  product = attrs[0].product(*attrs[1..-1])
  product.map{ |p| Hash[keys.zip p] }
end

print "::set-output name=matrix_json::"
puts product_hash(ENTRIES).to_json

print "::set-output name=crystal_version::"
puts SHARD_YML['crystal']
