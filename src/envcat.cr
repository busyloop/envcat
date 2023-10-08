require "./envcat/cli"

module Envcat
  class StdinAlreadyClaimedError < Exception; end

  @@stdin_claimed = false

  def self.claim_stdin!
    raise StdinAlreadyClaimedError.new if @@stdin_claimed
    @@stdin_claimed = true
  end
end

{% unless @top_level.constant("BUILD_ENV") == :spec %}
  Envcat::Cli.invoke
{% end %}
