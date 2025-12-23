# frozen_string_literal: true

$stdout.sync = true

require "yaml"
require "singleton"
require "optparse"
require "erb"
require "fileutils"

require "sidekiq"
require "sidekiq/config"
require "sidekiq/component"
require "sidekiq/capsule"
require "sidekiq/launcher"

module Sidekiq # :nodoc:
  class CLI
    include Sidekiq::Component
    include Singleton unless $TESTING

    attr_accessor :launcher
    attr_accessor :environment
    attr_accessor :config

    def parse(args = ARGV.dup)
      @config ||= Sidekiq.default_configuration

      setup_options(args)
      initialize_logger
      validate!
    end

    def jruby?
      defined?(::JRUBY_VERSION)
    end

    # Code within this method is not tested because it alters
    # global process state irreversibly.  PRs which improve the
    # test coverage of Sidekiq::CLI are welcomed.
    def run(boot_app: true, warmup: true)
      boot_application if boot_app

      if environment == "development" && $stdout.tty? && @config.logger.formatter.is_a?(Sidekiq::Logger::Formatters::Pretty)
        print_banner
      end
      logger.info "Booted Rails #{::Rails.version} application in #{environment} environment" if rails_app?

      self_read, self_write = IO.pipe
      sigs = %w[INT TERM TTIN TSTP]
      # USR1 and USR2 don't work on the JVM
      sigs << "USR2" if Sidekiq.pro? && !jruby?
      sigs.each do |sig|
        old_handler = Signal.trap(sig) do
          if old_handler.respond_to?(:call)
            begin
              old_handler.call
            rescue Exception => exc
              # signal handlers can't use Logger so puts only
              puts ["Error in #{sig} handler", exc].inspect
            end
          end
          self_write.puts(sig)
        end
      rescue ArgumentError
        puts "Signal #{sig} not supported"
      end

      logger.info "Running in #{RUBY_DESCRIPTION}"
      logger.info Sidekiq::LICENSE
      logger.info "Upgrade to Sidekiq Pro for more features and support: https://sidekiq.org" unless defined?(::Sidekiq::Pro)

      # touch the connection pool so it is created before we
      # fire startup and start multithreading.
      info = @config.redis_info
      ver = Gem::Version.new(info["redis_version"])
      raise "You are connecting to Redis #{ver}, Sidekiq requires Redis 6.2.0 or greater" if ver < Gem::Version.new("6.2.0")

      maxmemory_policy = info["maxmemory_policy"]
      if maxmemory_policy != "noeviction" && maxmemory_policy != ""
        # Redis Enterprise Cloud returns "" for their policy 😳
        logger.warn <<~EOM


          WARNING: Your Redis instance will evict Sidekiq data under heavy load.
          The 'noeviction' maxmemory policy is recommended (current policy: '#{maxmemory_policy}').
          See: https://github.com/sidekiq/sidekiq/wiki/Using-Redis#memory

        EOM
      end

      # Since the user can pass us a connection pool explicitly in the initializer, we
      # need to verify the size is large enough or else Sidekiq's performance is dramatically slowed.
      @config.capsules.each_pair do |name, cap|
        raise ArgumentError, "Pool size too small for #{name}" if cap.redis_pool.size < cap.concurrency
      end

      # cache process identity
      @config[:identity] = identity

      # Touch middleware so it isn't lazy loaded by multiple threads, #3043
      @config.server_middleware

      ::Process.warmup if warmup && ::Process.respond_to?(:warmup)

      # Before this point, the process is initializing with just the main thread.
      # Starting here the process will now have multiple threads running.
      fire_event(:startup, reverse: false, reraise: true)

      logger.debug { "Client Middleware: #{@config.default_capsule.client_middleware.map(&:klass).join(", ")}" }
      logger.debug { "Server Middleware: #{@config.default_capsule.server_middleware.map(&:klass).join(", ")}" }

      launch(self_read)
    end

    def launch(self_read)
      if environment == "development" && $stdout.tty?
        logger.info "Starting processing, hit Ctrl-C to stop"
      end

      @launcher = Sidekiq::Launcher.new(@config)

      begin
        launcher.run

        while self_read.wait_readable
          signal = self_read.gets.strip
          handle_signal(signal)
        end
      rescue Interrupt
        logger.info "Shutting down"
        launcher.stop
        logger.info "Bye!"

        # Explicitly exit so busy Processor threads won't block process shutdown.
        #
        # NB: slow at_exit handlers will prevent a timely exit if they take
        # a while to run. If Sidekiq is getting here but the process isn't exiting,
        # use the TTIN signal to determine where things are stuck.
        exit(0)
      end
    end

    HOLIDAY_COLORS = {
      # got other color-specific holidays from around the world?
      # https://developer-book.com/post/definitive-guide-for-colored-text-in-terminal/#256-color-escape-codes
      "3-17" => "\e[1;32m", # St. Patrick's Day green
      "10-31" => "\e[38;5;208m" # Halloween orange
    }

    def self.day
      @@day ||= begin
        t = Date.today
        "#{t.month}-#{t.day}"
      end
    end

    def self.r
      @@r ||= HOLIDAY_COLORS[day] || "\e[1;31m"
    end

    def self.b
      @@b ||= HOLIDAY_COLORS[day] || "\e[30m"
    end

    def self.w
      "\e[1;37m"
    end

    def self.reset
      @@b = @@r = @@day = nil
      "\e[0m"
    end

    def self.banner
      %{
      #{w}         m,
      #{w}         `$b
      #{w}    .ss,  $$:         .,d$
      #{w}    `$$P,d$P'    .,md$P"'
      #{w}     ,$$$$$b#{b}/#{w}md$$$P^'
      #{w}   .d$$$$$$#{b}/#{w}$$$P'
      #{w}   $$^' `"#{b}/#{w}$$$'       #{r}____  _     _      _    _
      #{w}   $:    #{b}'#{w},$$:      #{r} / ___|(_) __| | ___| | _(_) __ _
      #{w}   `b     :$$       #{r} \\___ \\| |/ _` |/ _ \\ |/ / |/ _` |
      #{w}          $$:        #{r} ___) | | (_| |  __/   <| | (_| |
      #{w}          $$         #{r}|____/|_|\\__,_|\\___|_|\\_\\_|\\__, |
      #{w}        .d$$          #{r}                             |_|
      #{reset}}
    end

    SIGNAL_HANDLERS = {
      # Ctrl-C in terminal
      "INT" => ->(cli) { raise Interrupt },
      # TERM is the signal that Sidekiq must exit.
      # Heroku sends TERM and then waits 30 seconds for process to exit.
      "TERM" => ->(cli) { raise Interrupt },
      "TSTP" => ->(cli) {
        cli.logger.info "Received TSTP, no longer accepting new work"
        cli.launcher.quiet
      },
      "TTIN" => ->(cli) {
        Thread.list.each do |thread|
          cli.logger.warn "Thread TID-#{(thread.object_id ^ ::Process.pid).to_s(36)} #{thread.name}"
          if thread.backtrace
            cli.logger.warn thread.backtrace.join("\n")
          else
            cli.logger.warn "<no backtrace available>"
          end
        end
      }
    }
    UNHANDLED_SIGNAL_HANDLER = ->(cli) { cli.logger.info "No signal handler registered, ignoring" }
    SIGNAL_HANDLERS.default = UNHANDLED_SIGNAL_HANDLER

    def handle_signal(sig)
      logger.debug "Got #{sig} signal"
      SIGNAL_HANDLERS[sig].call(self)
    end

    private

    def print_banner
      puts "\e[31m"
      puts Sidekiq::CLI.banner
      puts "\e[0m"
    end

    def set_environment(cli_env)
      # See #984 for discussion.
      # APP_ENV is now the preferred ENV term since it is not tech-specific.
      # Both Sinatra 2.0+ and Sidekiq support this term.
      # RAILS_ENV and RACK_ENV are there for legacy support.
      @environment = cli_env || ENV["APP_ENV"] || ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
      config[:environment] = @environment
    end

    def symbolize_keys_deep!(hash)
      hash.keys.each do |k|
        symkey = k.respond_to?(:to_sym) ? k.to_sym : k
        hash[symkey] = hash.delete k
        symbolize_keys_deep! hash[symkey] if hash[symkey].is_a? Hash
      end
    end

    alias_method :die, :exit
    alias_method :☠, :exit

    def setup_options(args)
      # parse CLI options
      opts = parse_options(args)

      set_environment opts[:environment]

      # check config file presence
      if opts[:config_file]
        unless File.exist?(opts[:config_file])
          raise ArgumentError, "No such file #{opts[:config_file]}"
        end
      else
        config_dir = if File.directory?(opts[:require].to_s)
          File.join(opts[:require], "config")
        else
          File.join(@config[:require], "config")
        end

        %w[sidekiq.yml sidekiq.yml.erb].each do |config_file|
          path = File.join(config_dir, config_file)
          opts[:config_file] ||= path if File.exist?(path)
        end
      end

      # parse config file options
      opts = parse_config(opts[:config_file]).merge(opts) if opts[:config_file]

      # set defaults
      opts[:queues] = ["default"] if opts[:queues].nil?
      opts[:concurrency] = Integer(ENV["RAILS_MAX_THREADS"]) if opts[:concurrency].nil? && ENV["RAILS_MAX_THREADS"]

      # merge with defaults
      @config.merge!(opts)

      @config.default_capsule.tap do |cap|
        cap.queues = opts[:queues]
        cap.concurrency = opts[:concurrency] || @config[:concurrency]
      end

      opts[:capsules]&.each do |name, cap_config|
        @config.capsule(name.to_s) do |cap|
          cap.queues = cap_config[:queues]
          cap.concurrency = cap_config[:concurrency]
        end
      end
    end

    def boot_application
      ENV["RACK_ENV"] = ENV["RAILS_ENV"] = environment

      if File.directory?(@config[:require])
        require "rails"
        if ::Rails::VERSION::MAJOR < 6
          warn "Sidekiq #{Sidekiq::VERSION} only supports Rails 6+"
        end
        require "sidekiq/rails"
        require File.expand_path("#{@config[:require]}/config/environment.rb")
        @config[:tag] ||= default_tag
      else
        require @config[:require]
      end
    end

    def default_tag
      dir = ::Rails.root
      name = File.basename(dir)
      prevdir = File.dirname(dir) # Capistrano release directory?
      if name.to_i != 0 && prevdir
        if File.basename(prevdir) == "releases"
          return File.basename(File.dirname(prevdir))
        end
      end
      name
    end

    def validate!
      if !File.exist?(@config[:require]) ||
          (File.directory?(@config[:require]) && !File.exist?("#{@config[:require]}/config/application.rb"))
        logger.info "=================================================================="
        logger.info "  Please point Sidekiq to a Rails application or a Ruby file  "
        logger.info "  to load your job classes with -r [DIR|FILE]."
        logger.info "=================================================================="
        logger.info @parser
        die(1)
      end

      [:concurrency, :timeout].each do |opt|
        raise ArgumentError, "#{opt}: #{@config[opt]} is not a valid value" if @config[opt].to_i <= 0
      end
    end

    def parse_options(argv)
      opts = {}
      @parser = option_parser(opts)
      @parser.parse!(argv)
      opts
    end

    def option_parser(opts)
      parser = OptionParser.new { |o|
        o.on "-c", "--concurrency INT", "processor threads to use" do |arg|
          opts[:concurrency] = Integer(arg)
        end

        o.on "-e", "--environment ENV", "Application environment" do |arg|
          opts[:environment] = arg
        end

        o.on "-g", "--tag TAG", "Process tag for procline" do |arg|
          opts[:tag] = arg
        end

        o.on "-q", "--queue QUEUE[,WEIGHT]", "Queues to process with optional weights" do |arg|
          opts[:queues] ||= []
          opts[:queues] << arg
        end

        o.on "-r", "--require [PATH|DIR]", "Location of Rails application with jobs or file to require" do |arg|
          opts[:require] = arg
        end

        o.on "-t", "--timeout NUM", "Shutdown timeout" do |arg|
          opts[:timeout] = Integer(arg)
        end

        o.on "-v", "--verbose", "Print more verbose output" do |arg|
          opts[:verbose] = arg
        end

        o.on "-C", "--config PATH", "path to YAML config file" do |arg|
          opts[:config_file] = arg
        end

        o.on "-V", "--version", "Print version and exit" do
          puts "Sidekiq #{Sidekiq::VERSION}"
          die(0)
        end
      }

      parser.banner = "sidekiq [options]"
      parser.on_tail "-h", "--help", "Show help" do
        logger.info parser
        die 1
      end

      parser
    end

    def initialize_logger
      @config.logger.level = ::Logger::DEBUG if @config[:verbose]
    end

    def parse_config(path)
      erb = ERB.new(File.read(path), trim_mode: "-")
      erb.filename = File.expand_path(path)
      opts = YAML.safe_load(erb.result, permitted_classes: [Symbol], aliases: true) || {}

      if opts.respond_to? :deep_symbolize_keys!
        opts.deep_symbolize_keys!
      else
        symbolize_keys_deep!(opts)
      end

      opts = opts.merge(opts.delete(environment.to_sym) || {})
      opts.delete(:strict)

      opts
    end

    def rails_app?
      defined?(::Rails) && ::Rails.respond_to?(:application)
    end
  end
end

require "sidekiq/systemd"
require "sidekiq/metrics/tracking"
require "sidekiq/job/interrupt_handler"
