require "./envcat/cli"

{% unless @top_level.constant("BUILD_ENV") == :spec %}
  Envcat::Cli.invoke
{% end %}
