require "./env"
require "./format/*"
require "./check"
require "./version"

require "toka"

class Envcat::Cli
  E_OK        =   0
  E_INVALID   =   1
  E_SYNTAX    =   3
  E_UNDEFINED =   5
  E_IO        =   7
  E_BUG       = 255

  HELP_FOOTER = <<-EOF
  See https://github.com/busyloop/envcat for documentation and usage examples.
  EOF

  class InvalidFlagArgumentError < Exception; end

  class ValidationErrors < Exception
    getter errors

    def initialize(@errors : Array(String))
    end
  end

  Toka.mapping({
    format: {
      type:        String,
      default:     Format::DEFAULT,
      value_name:  "FORMAT",
      description: Format.keys.sort!.join("|") + " (default: #{Format::DEFAULT})",
    },
    check: {
      type:        Array(String),
      description: "Check VAR against SPEC. Omit SPEC to check only for presence.",
      value_name:  "VAR[:SPEC]",
      short:       ["c"],
    },
    help: {
      type:        Bool?,
      description: "Show this help",
    },
    version: {
      type:        Bool?,
      short:       false,
      description: "Print version and exit",
    },
  }, {
    banner: "\nUsage: envcat [-f #{Format.keys.join("|")}] [-c <SPEC> ..] [GLOB[:etf] ..]\n\n",
    help:   false,
  })

  def self.help
    String.build(4096) do |s|
      s.puts "FORMAT"

      Format.keys.sort!.each do |fmt_id|
        s.printf "  %-16s  %s\n", fmt_id, Format[fmt_id].description
      end

      s.puts
      s.puts "SPEC"

      Envcat::Check::CONSTRAINTS.keys.each do |cid|
        Check.help_for(s, cid)
      end

      s.puts
      s.puts "  Prefix ? to skip check when VAR is undefined."

      s.puts
      s.puts HELP_FOOTER
      s.puts
    end
  end

  def self.be_helpful(opts, io)
    if opts.help || (opts.format == Format::DEFAULT && opts.check.empty? && opts.positional_options.empty?)
      io.puts Toka::HelpPageRenderer.new(self)
      io.puts help
      exit opts.help ? E_OK : E_SYNTAX
    end
  end

  def self.process_version_flag(opts, io)
    if opts.version
      io.puts "envcat #{Envcat::VERSION} #{{{env("UNAME") || "unknown-unknown"}}}"
      exit E_OK
    end
  end

  def self.process_check_flags(opts)
    validation_errors = [] of String
    opts.check.try &.each do |vspec|
      args = vspec.split(':')
      var_name = args.shift
      constraint_id = args.shift rescue "presence"
      if constraint_id.starts_with? '?'
        permit_undefined = true
        constraint_id = constraint_id.lchop('?')
      else
        permit_undefined = false
      end
      error = Check.invalid? ENV, var_name, constraint_id, args, permit_undefined
      validation_errors << error if error.is_a?(String)
    rescue ex : Check::UnknownConstraintIdError | Check::ArgumentError
      raise InvalidFlagArgumentError.new("-c #{vspec}", cause: ex)
    end
    raise ValidationErrors.new(validation_errors) unless validation_errors.empty?
  end

  def self.process_format_flag(opts, io_out, io_err, io_in)
    env = Envcat::Env.new(ENV, opts.positional_options)
    Envcat::Format[opts.format].new(io_out, io_in).write(env)
  end

  def self.check_format_flag(opts)
    Format[opts.format]
  end

  def self.invoke(argv = ARGV, io_out = STDOUT, io_err = STDERR, io_in = STDIN)
    opts = new(argv)

    process_version_flag(opts, io_out)
    be_helpful(opts, io_err)
    check_format_flag(opts) # fail-fast on bad syntax
    process_check_flags(opts)
    process_format_flag(opts, io_out, io_err, io_in)
  rescue ex : Toka::MissingOptionError | Toka::MissingValueError | Toka::ConversionError | Toka::UnknownOptionError
    io_err.puts Toka::HelpPageRenderer.new(Envcat::Cli)
    io_err.puts "Syntax error: #{ex}"
    exit E_SYNTAX
  rescue ex : ValidationErrors
    io_err.puts ex.errors.join("\n")
    exit E_INVALID
  rescue ex : IO::Error
    io_err.print "Error: "
    io_err.puts ex
    exit E_IO
  rescue ex : Format::J2::UndefinedVariableError
    if ex.message.try &.includes? ','
      io_err.puts "Undefined variables: #{ex.message}"
    else
      io_err.puts "Undefined variable: #{ex.message}"
    end
    exit E_UNDEFINED
  rescue ex : InvalidFlagArgumentError
    io_err.puts "Invalid flag: #{ex.message}"
    if cause = ex.cause
      io_err.puts "Reason: #{cause.message}"
    end
    exit E_SYNTAX
  rescue ex : Format::MalformedInputError | Format::InvalidModeError
    io_err.puts "Malformed input: #{ex.message}"
    if cause = ex.cause
      io_err.puts "Reason: #{cause.message}"
    end
    exit E_INVALID
  rescue ex : Format::UnknownFormatIdError
    io_err.puts "Unknown format: #{ex.message}"
    exit E_SYNTAX
  rescue ex : Crinja::TemplateSyntaxError | Crinja::FeatureLibrary::UnknownFeatureError | Crinja::TypeError
    io_err.puts "Malformed template: #{ex.message}"
    exit E_SYNTAX
  rescue ex : Exception
    {% if @top_level.constant("BUILD_ENV") == :spec %}
      raise ex
    {% else %}
      STDERR.puts
      STDOUT.puts "BUG: #{ex.class} #{ex.message}"
      STDERR.puts "🚨 Please report to: https://github.com/busyloop/envcat/issues/new 🚨"
      STDERR.puts
      3.times do
        STDOUT.print("\a")
        sleep 0.42
      end
      STDERR.puts "Include the following in your report:"
      STDERR.puts "--"
      STDERR.puts "VERSION: #{Envcat::VERSION}"
      STDERR.puts "ARGV: #{ARGV}"
      STDERR.puts "TRACE: #{ex.class} #{ex.message}\n#{ex.backtrace.join("\n")}"
      STDERR.puts "--"
      STDERR.puts
      exit E_BUG
    {% end %}
  end
end
