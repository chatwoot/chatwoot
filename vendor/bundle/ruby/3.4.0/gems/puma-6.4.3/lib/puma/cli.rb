# frozen_string_literal: true

require 'optparse'
require 'uri'

require_relative '../puma'
require_relative 'configuration'
require_relative 'launcher'
require_relative 'const'
require_relative 'log_writer'

module Puma
  class << self
    # The CLI exports a Puma::Configuration instance here to allow
    # apps to pick it up. An app must load this object conditionally
    # because it is not set if the app is launched via any mechanism
    # other than the CLI class.
    attr_accessor :cli_config
  end

  # Handles invoke a Puma::Server in a command line style.
  #
  class CLI
    # Create a new CLI object using +argv+ as the command line
    # arguments.
    #
    def initialize(argv, log_writer = LogWriter.stdio, events = Events.new)
      @debug = false
      @argv = argv.dup
      @log_writer = log_writer
      @events = events

      @conf = nil

      @stdout = nil
      @stderr = nil
      @append = false

      @control_url = nil
      @control_options = {}

      setup_options

      begin
        @parser.parse! @argv

        if file = @argv.shift
          @conf.configure do |user_config, file_config|
            file_config.rackup file
          end
        end
      rescue UnsupportedOption
        exit 1
      end

      @conf.configure do |user_config, file_config|
        if @stdout || @stderr
          user_config.stdout_redirect @stdout, @stderr, @append
        end

        if @control_url
          user_config.activate_control_app @control_url, @control_options
        end
      end

      @launcher = Puma::Launcher.new(@conf, :log_writer => @log_writer, :events => @events, :argv => argv)
    end

    attr_reader :launcher

    # Parse the options, load the rackup, start the server and wait
    # for it to finish.
    #
    def run
      @launcher.run
    end

    private
    def unsupported(str)
      @log_writer.error(str)
      raise UnsupportedOption
    end

    def configure_control_url(command_line_arg)
      if command_line_arg
        @control_url = command_line_arg
      elsif Puma.jruby?
        unsupported "No default url available on JRuby"
      end
    end

    # Build the OptionParser object to handle the available options.
    #

    def setup_options
      @conf = Configuration.new({}, {events: @events}) do |user_config, file_config|
        @parser = OptionParser.new do |o|
          o.on "-b", "--bind URI", "URI to bind to (tcp://, unix://, ssl://)" do |arg|
            user_config.bind arg
          end

          o.on "--bind-to-activated-sockets [only]", "Bind to all activated sockets" do |arg|
            user_config.bind_to_activated_sockets(arg || true)
          end

          o.on "-C", "--config PATH", "Load PATH as a config file" do |arg|
            file_config.load arg
          end

          # Identical to supplying --config "-", but more semantic
          o.on "--no-config", "Prevent Puma from searching for a config file" do |arg|
            file_config.load "-"
          end

          o.on "--control-url URL", "The bind url to use for the control server. Use 'auto' to use temp unix server" do |arg|
            configure_control_url(arg)
          end

          o.on "--control-token TOKEN",
            "The token to use as authentication for the control server" do |arg|
            @control_options[:auth_token] = arg
          end

          o.on "--debug", "Log lowlevel debugging information" do
            user_config.debug
          end

          o.on "--dir DIR", "Change to DIR before starting" do |d|
            user_config.directory d
          end

          o.on "-e", "--environment ENVIRONMENT",
            "The environment to run the Rack app on (default development)" do |arg|
            user_config.environment arg
          end

          o.on "-f", "--fork-worker=[REQUESTS]", OptionParser::DecimalInteger,
            "Fork new workers from existing worker. Cluster mode only",
            "Auto-refork after REQUESTS (default 1000)" do |*args|
            user_config.fork_worker(*args.compact)
          end

          o.on "-I", "--include PATH", "Specify $LOAD_PATH directories" do |arg|
            $LOAD_PATH.unshift(*arg.split(':'))
          end

          o.on "--idle-timeout SECONDS", "Number of seconds until the next request before automatic shutdown" do |arg|
            user_config.idle_timeout arg
          end

          o.on "-p", "--port PORT", "Define the TCP port to bind to",
            "Use -b for more advanced options" do |arg|
            user_config.bind "tcp://#{Configuration::DEFAULTS[:tcp_host]}:#{arg}"
          end

          o.on "--pidfile PATH", "Use PATH as a pidfile" do |arg|
            user_config.pidfile arg
          end

          o.on "--preload", "Preload the app. Cluster mode only" do
            user_config.preload_app!
          end

          o.on "--prune-bundler", "Prune out the bundler env if possible" do
            user_config.prune_bundler
          end

          o.on "--extra-runtime-dependencies GEM1,GEM2", "Defines any extra needed gems when using --prune-bundler" do |arg|
            user_config.extra_runtime_dependencies arg.split(',')
          end

          o.on "-q", "--quiet", "Do not log requests internally (default true)" do
            user_config.quiet
          end

          o.on "-v", "--log-requests", "Log requests as they occur" do
            user_config.log_requests
          end

          o.on "-R", "--restart-cmd CMD",
            "The puma command to run during a hot restart",
            "Default: inferred" do |cmd|
            user_config.restart_command cmd
          end

          o.on "-s", "--silent", "Do not log prompt messages other than errors" do
            @log_writer = LogWriter.new(NullIO.new, $stderr)
          end

          o.on "-S", "--state PATH", "Where to store the state details" do |arg|
            user_config.state_path arg
          end

          o.on '-t', '--threads INT', "min:max threads to use (default 0:16)" do |arg|
            min, max = arg.split(":")
            if max
              user_config.threads min, max
            else
              user_config.threads min, min
            end
          end

          o.on "--early-hints", "Enable early hints support" do
            user_config.early_hints
          end

          o.on "-V", "--version", "Print the version information" do
            puts "puma version #{Puma::Const::VERSION}"
            exit 0
          end

          o.on "-w", "--workers COUNT",
            "Activate cluster mode: How many worker processes to create" do |arg|
            user_config.workers arg
          end

          o.on "--tag NAME", "Additional text to display in process listing" do |arg|
            user_config.tag arg
          end

          o.on "--redirect-stdout FILE", "Redirect STDOUT to a specific file" do |arg|
            @stdout = arg.to_s
          end

          o.on "--redirect-stderr FILE", "Redirect STDERR to a specific file" do |arg|
            @stderr = arg.to_s
          end

          o.on "--[no-]redirect-append", "Append to redirected files" do |val|
            @append = val
          end

          o.banner = "puma <options> <rackup file>"

          o.on_tail "-h", "--help", "Show help" do
            $stdout.puts o
            exit 0
          end
        end
      end
    end
  end
end
