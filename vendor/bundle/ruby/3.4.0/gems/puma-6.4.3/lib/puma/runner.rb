# frozen_string_literal: true

require_relative 'server'
require_relative 'const'

module Puma
  # Generic class that is used by `Puma::Cluster` and `Puma::Single` to
  # serve requests. This class spawns a new instance of `Puma::Server` via
  # a call to `start_server`.
  class Runner
    def initialize(launcher)
      @launcher = launcher
      @log_writer = launcher.log_writer
      @events = launcher.events
      @config = launcher.config
      @options = launcher.options
      @app = nil
      @control = nil
      @started_at = Time.now
      @wakeup = nil
    end

    # Returns the hash of configuration options.
    # @return [Puma::UserFileDefaultOptions]
    attr_reader :options

    def wakeup!
      return unless @wakeup

      @wakeup.write "!" unless @wakeup.closed?

    rescue SystemCallError, IOError
      Puma::Util.purge_interrupt_queue
    end

    def development?
      @options[:environment] == "development"
    end

    def test?
      @options[:environment] == "test"
    end

    def log(str)
      @log_writer.log str
    end

    # @version 5.0.0
    def stop_control
      @control&.stop true
    end

    def error(str)
      @log_writer.error str
    end

    def debug(str)
      @log_writer.log "- #{str}" if @options[:debug]
    end

    def start_control
      str = @options[:control_url]
      return unless str

      require_relative 'app/status'

      if token = @options[:control_auth_token]
        token = nil if token.empty? || token == 'none'
      end

      app = Puma::App::Status.new @launcher, token

      # A Reactor is not created and nio4r is not loaded when 'queue_requests: false'
      # Use `nil` for events, no hooks in control server
      control = Puma::Server.new app, nil,
        { min_threads: 0, max_threads: 1, queue_requests: false, log_writer: @log_writer }

      begin
        control.binder.parse [str], nil, 'Starting control server'
      rescue Errno::EADDRINUSE, Errno::EACCES => e
        raise e, "Error: Control server address '#{str}' is already in use. Original error: #{e.message}"
      end

      control.run thread_name: 'ctl'
      @control = control
    end

    # @version 5.0.0
    def close_control_listeners
      @control.binder.close_listeners if @control
    end

    # @!attribute [r] ruby_engine
    def ruby_engine
      if !defined?(RUBY_ENGINE) || RUBY_ENGINE == "ruby"
        "ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
      else
        if defined?(RUBY_ENGINE_VERSION)
          "#{RUBY_ENGINE} #{RUBY_ENGINE_VERSION} - ruby #{RUBY_VERSION}"
        else
          "#{RUBY_ENGINE} #{RUBY_VERSION}"
        end
      end
    end

    def output_header(mode)
      min_t = @options[:min_threads]
      max_t = @options[:max_threads]
      environment = @options[:environment]

      log "Puma starting in #{mode} mode..."
      log "* Puma version: #{Puma::Const::PUMA_VERSION} (#{ruby_engine}) (\"#{Puma::Const::CODE_NAME}\")"
      log "*  Min threads: #{min_t}"
      log "*  Max threads: #{max_t}"
      log "*  Environment: #{environment}"

      if mode == "cluster"
        log "*   Master PID: #{Process.pid}"
      else
        log "*          PID: #{Process.pid}"
      end
    end

    def redirected_io?
      @options[:redirect_stdout] || @options[:redirect_stderr]
    end

    def redirect_io
      stdout = @options[:redirect_stdout]
      stderr = @options[:redirect_stderr]
      append = @options[:redirect_append]

      if stdout
        ensure_output_directory_exists(stdout, 'STDOUT')

        STDOUT.reopen stdout, (append ? "a" : "w")
        STDOUT.puts "=== puma startup: #{Time.now} ==="
        STDOUT.flush unless STDOUT.sync
      end

      if stderr
        ensure_output_directory_exists(stderr, 'STDERR')

        STDERR.reopen stderr, (append ? "a" : "w")
        STDERR.puts "=== puma startup: #{Time.now} ==="
        STDERR.flush unless STDERR.sync
      end

      if @options[:mutate_stdout_and_stderr_to_sync_on_write]
        STDOUT.sync = true
        STDERR.sync = true
      end
    end

    def load_and_bind
      unless @config.app_configured?
        error "No application configured, nothing to run"
        exit 1
      end

      begin
        @app = @config.app
      rescue Exception => e
        log "! Unable to load application: #{e.class}: #{e.message}"
        raise e
      end

      @launcher.binder.parse @options[:binds]
    end

    # @!attribute [r] app
    def app
      @app ||= @config.app
    end

    def start_server
      server = Puma::Server.new(app, @events, @options)
      server.inherit_binder(@launcher.binder)
      server
    end

    private
    def ensure_output_directory_exists(path, io_name)
      unless Dir.exist?(File.dirname(path))
        raise "Cannot redirect #{io_name} to #{path}"
      end
    end

    def utc_iso8601(val)
      "#{val.utc.strftime '%FT%T'}Z"
    end

    def stats
      {
        versions: {
          puma: Puma::Const::PUMA_VERSION,
          ruby: {
            engine: RUBY_ENGINE,
            version: RUBY_VERSION,
            patchlevel: RUBY_PATCHLEVEL
          }
        }
      }
    end

    # this method call should always be guarded by `@log_writer.debug?`
    def debug_loaded_extensions(str)
      @log_writer.debug "────────────────────────────────── #{str}"
      re_ext = /\.#{RbConfig::CONFIG['DLEXT']}\z/i
      $LOADED_FEATURES.grep(re_ext).each { |f| @log_writer.debug("    #{f}") }
    end
  end
end
