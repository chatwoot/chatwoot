# frozen_string_literal: true

require_relative 'log_writer'
require_relative 'events'
require_relative 'detect'
require_relative 'cluster'
require_relative 'single'
require_relative 'const'
require_relative 'binder'

module Puma
  # Puma::Launcher is the single entry point for starting a Puma server based on user
  # configuration. It is responsible for taking user supplied arguments and resolving them
  # with configuration in `config/puma.rb` or `config/puma/<env>.rb`.
  #
  # It is responsible for either launching a cluster of Puma workers or a single
  # puma server.
  class Launcher
    autoload :BundlePruner, 'puma/launcher/bundle_pruner'

    # Returns an instance of Launcher
    #
    # +conf+ A Puma::Configuration object indicating how to run the server.
    #
    # +launcher_args+ A Hash that currently has one required key `:events`,
    # this is expected to hold an object similar to an `Puma::LogWriter.stdio`,
    # this object will be responsible for broadcasting Puma's internal state
    # to a logging destination. An optional key `:argv` can be supplied,
    # this should be an array of strings, these arguments are re-used when
    # restarting the puma server.
    #
    # Examples:
    #
    #   conf = Puma::Configuration.new do |user_config|
    #     user_config.threads 1, 10
    #     user_config.app do |env|
    #       [200, {}, ["hello world"]]
    #     end
    #   end
    #   Puma::Launcher.new(conf, log_writer: Puma::LogWriter.stdio).run
    def initialize(conf, launcher_args={})
      @runner        = nil
      @log_writer    = launcher_args[:log_writer] || LogWriter::DEFAULT
      @events        = launcher_args[:events] || Events.new
      @argv          = launcher_args[:argv] || []
      @original_argv = @argv.dup
      @config        = conf

      @config.options[:log_writer] = @log_writer

      # Advertise the Configuration
      Puma.cli_config = @config if defined?(Puma.cli_config)

      @config.load

      @binder        = Binder.new(@log_writer, conf)
      @binder.create_inherited_fds(ENV).each { |k| ENV.delete k }
      @binder.create_activated_fds(ENV).each { |k| ENV.delete k }

      @environment = conf.environment

      # Load the systemd integration if we detect systemd's NOTIFY_SOCKET.
      # Skip this on JRuby though, because it is incompatible with the systemd
      # integration due to https://github.com/jruby/jruby/issues/6504
      if ENV["NOTIFY_SOCKET"] && !Puma.jruby?
        @config.plugins.create('systemd')
      end

      if @config.options[:bind_to_activated_sockets]
        @config.options[:binds] = @binder.synthesize_binds_from_activated_fs(
          @config.options[:binds],
          @config.options[:bind_to_activated_sockets] == 'only'
        )
      end

      @options = @config.options
      @config.clamp

      @log_writer.formatter = LogWriter::PidFormatter.new if clustered?
      @log_writer.formatter = options[:log_formatter] if @options[:log_formatter]

      @log_writer.custom_logger = options[:custom_logger] if @options[:custom_logger]

      generate_restart_data

      if clustered? && !Puma.forkable?
        unsupported "worker mode not supported on #{RUBY_ENGINE} on this platform"
      end

      Dir.chdir(@restart_dir)

      prune_bundler!

      @environment = @options[:environment] if @options[:environment]
      set_rack_environment

      if clustered?
        @options[:logger] = @log_writer

        @runner = Cluster.new(self)
      else
        @runner = Single.new(self)
      end
      Puma.stats_object = @runner

      @status = :run

      log_config if ENV['PUMA_LOG_CONFIG']
    end

    attr_reader :binder, :log_writer, :events, :config, :options, :restart_dir

    # Return stats about the server
    def stats
      @runner.stats
    end

    # Write a state file that can be used by pumactl to control
    # the server
    def write_state
      write_pid

      path = @options[:state]
      permission = @options[:state_permission]
      return unless path

      require_relative 'state_file'

      sf = StateFile.new
      sf.pid = Process.pid
      sf.control_url = @options[:control_url]
      sf.control_auth_token = @options[:control_auth_token]
      sf.running_from = File.expand_path('.')

      sf.save path, permission
    end

    # Delete the configured pidfile
    def delete_pidfile
      path = @options[:pidfile]
      File.unlink(path) if path && File.exist?(path)
    end

    # Begin async shutdown of the server
    def halt
      @status = :halt
      @runner.halt
    end

    # Begin async shutdown of the server gracefully
    def stop
      @status = :stop
      @runner.stop
    end

    # Begin async restart of the server
    def restart
      @status = :restart
      @runner.restart
    end

    # Begin a phased restart if supported
    def phased_restart
      unless @runner.respond_to?(:phased_restart) and @runner.phased_restart
        log "* phased-restart called but not available, restarting normally."
        return restart
      end
      true
    end

    # Begin a refork if supported
    def refork
      if clustered? && @runner.respond_to?(:fork_worker!) && @options[:fork_worker]
        @runner.fork_worker!
        true
      else
        log "* refork called but not available."
        false
      end
    end

    # Run the server. This blocks until the server is stopped
    def run
      previous_env = get_env

      @config.clamp

      @config.plugins.fire_starts self

      setup_signals
      set_process_title

      # This blocks until the server is stopped
      @runner.run

      do_run_finished(previous_env)
    end

    # Return all tcp ports the launcher may be using, TCP or SSL
    # @!attribute [r] connected_ports
    # @version 5.0.0
    def connected_ports
      @binder.connected_ports
    end

    # @!attribute [r] restart_args
    def restart_args
      cmd = @options[:restart_cmd]
      if cmd
        cmd.split(' ') + @original_argv
      else
        @restart_argv
      end
    end

    def close_binder_listeners
      @runner.close_control_listeners
      @binder.close_listeners
      unless @status == :restart
        log "=== puma shutdown: #{Time.now} ==="
        log "- Goodbye!"
      end
    end

    # @!attribute [r] thread_status
    # @version 5.0.0
    def thread_status
      Thread.list.each do |thread|
        name = "Thread: TID-#{thread.object_id.to_s(36)}"
        name += " #{thread['label']}" if thread['label']
        name += " #{thread.name}" if thread.respond_to?(:name) && thread.name
        backtrace = thread.backtrace || ["<no backtrace available>"]

        yield name, backtrace
      end
    end

    private

    def get_env
      if defined?(Bundler)
        env = Bundler::ORIGINAL_ENV.dup
        # add -rbundler/setup so we load from Gemfile when restarting
        bundle = "-rbundler/setup"
        env["RUBYOPT"] = [env["RUBYOPT"], bundle].join(" ").lstrip unless env["RUBYOPT"].to_s.include?(bundle)
        env
      else
        ENV.to_h
      end
    end

    def do_run_finished(previous_env)
      case @status
      when :halt
        do_forceful_stop
      when :run, :stop
        do_graceful_stop
      when :restart
        do_restart(previous_env)
      end

      close_binder_listeners unless @status == :restart
    end

    def do_forceful_stop
      log "* Stopping immediately!"
      @runner.stop_control
    end

    def do_graceful_stop
      @events.fire_on_stopped!
      @runner.stop_blocked
    end

    def do_restart(previous_env)
      log "* Restarting..."
      ENV.replace(previous_env)
      @runner.stop_control
      restart!
    end

    def restart!
      @events.fire_on_restart!
      @config.run_hooks :on_restart, self, @log_writer

      if Puma.jruby?
        close_binder_listeners

        require_relative 'jruby_restart'
        JRubyRestart.chdir_exec(@restart_dir, restart_args)
      elsif Puma.windows?
        close_binder_listeners

        argv = restart_args
        Dir.chdir(@restart_dir)
        Kernel.exec(*argv)
      else
        argv = restart_args
        Dir.chdir(@restart_dir)
        ENV.update(@binder.redirects_for_restart_env)
        argv += [@binder.redirects_for_restart]
        Kernel.exec(*argv)
      end
    end

    # If configured, write the pid of the current process out
    # to a file.
    def write_pid
      path = @options[:pidfile]
      return unless path
      cur_pid = Process.pid
      File.write path, cur_pid, mode: 'wb:UTF-8'
      at_exit do
        delete_pidfile if cur_pid == Process.pid
      end
    end

    def reload_worker_directory
      @runner.reload_worker_directory if @runner.respond_to?(:reload_worker_directory)
    end

    def log(str)
      @log_writer.log(str)
    end

    def clustered?
      (@options[:workers] || 0) > 0
    end

    def unsupported(str)
      @log_writer.error(str)
      raise UnsupportedOption
    end

    def set_process_title
      Process.respond_to?(:setproctitle) ? Process.setproctitle(title) : $0 = title
    end

    # @!attribute [r] title
    def title
      buffer  = "puma #{Puma::Const::VERSION} (#{@options[:binds].join(',')})"
      buffer += " [#{@options[:tag]}]" if @options[:tag] && !@options[:tag].empty?
      buffer
    end

    def set_rack_environment
      @options[:environment] = environment
      ENV['RACK_ENV'] = environment
    end

    # @!attribute [r] environment
    def environment
      @environment
    end

    def prune_bundler?
      @options[:prune_bundler] && clustered? && !@options[:preload_app]
    end

    def prune_bundler!
      return unless prune_bundler?
      BundlePruner.new(@original_argv, @options[:extra_runtime_dependencies], @log_writer).prune
    end

    def generate_restart_data
      if dir = @options[:directory]
        @restart_dir = dir

      elsif Puma.windows?
        # I guess the value of PWD is garbage on windows so don't bother
        # using it.
        @restart_dir = Dir.pwd

        # Use the same trick as unicorn, namely favor PWD because
        # it will contain an unresolved symlink, useful for when
        # the pwd is /data/releases/current.
      elsif dir = ENV['PWD']
        s_env = File.stat(dir)
        s_pwd = File.stat(Dir.pwd)

        if s_env.ino == s_pwd.ino and (Puma.jruby? or s_env.dev == s_pwd.dev)
          @restart_dir = dir
        end
      end

      @restart_dir ||= Dir.pwd

      # if $0 is a file in the current directory, then restart
      # it the same, otherwise add -S on there because it was
      # picked up in PATH.
      #
      if File.exist?($0)
        arg0 = [Gem.ruby, $0]
      else
        arg0 = [Gem.ruby, "-S", $0]
      end

      # Detect and reinject -Ilib from the command line, used for testing without bundler
      # cruby has an expanded path, jruby has just "lib"
      lib = File.expand_path "lib"
      arg0[1,0] = ["-I", lib] if [lib, "lib"].include?($LOAD_PATH[0])

      if defined? Puma::WILD_ARGS
        @restart_argv = arg0 + Puma::WILD_ARGS + @original_argv
      else
        @restart_argv = arg0 + @original_argv
      end
    end

    def setup_signals
      begin
        Signal.trap "SIGUSR2" do
          restart
        end
      rescue Exception
        log "*** SIGUSR2 not implemented, signal based restart unavailable!"
      end

      unless Puma.jruby?
        begin
          Signal.trap "SIGUSR1" do
            phased_restart
          end
        rescue Exception
          log "*** SIGUSR1 not implemented, signal based restart unavailable!"
        end
      end

      begin
        Signal.trap "SIGTERM" do
          # Shortcut the control flow in case raise_exception_on_sigterm is true
          do_graceful_stop

          raise(SignalException, "SIGTERM") if @options[:raise_exception_on_sigterm]
        end
      rescue Exception
        log "*** SIGTERM not implemented, signal based gracefully stopping unavailable!"
      end

      begin
        Signal.trap "SIGINT" do
          stop
        end
      rescue Exception
        log "*** SIGINT not implemented, signal based gracefully stopping unavailable!"
      end

      begin
        Signal.trap "SIGHUP" do
          if @runner.redirected_io?
            @runner.redirect_io
          else
            stop
          end
        end
      rescue Exception
        log "*** SIGHUP not implemented, signal based logs reopening unavailable!"
      end

      begin
        unless Puma.jruby? # INFO in use by JVM already
          Signal.trap "SIGINFO" do
            thread_status do |name, backtrace|
              @log_writer.log(name)
              @log_writer.log(backtrace.map { |bt| "  #{bt}" })
            end
          end
        end
      rescue Exception
        # Not going to log this one, as SIGINFO is *BSD only and would be pretty annoying
        # to see this constantly on Linux.
      end
    end

    def log_config
      log "Configuration:"

      @config.final_options
        .each { |config_key, value| log "- #{config_key}: #{value}" }

      log "\n"
    end
  end
end
