module Spring
  ORIGINAL_ENV = ENV.to_hash
end

require "spring/boot"
require "spring/application_manager"

# Must be last, as it requires bundler/setup, which alters the load path
require "spring/commands"

module Spring
  class Server
    def self.boot(options = {})
      new(options).boot
    end

    attr_reader :env

    def initialize(options = {})
      @foreground   = options.fetch(:foreground, false)
      @env          = options[:env] || default_env
      @applications = Hash.new { |h, k| h[k] = ApplicationManager.new(k, env) }
      @pidfile      = env.pidfile_path.open('a')
      @mutex        = Mutex.new
    end

    def foreground?
      @foreground
    end

    def log(message)
      env.log "[server] #{message}"
    end

    def boot
      Spring.verify_environment

      write_pidfile
      set_pgid unless foreground?
      ignore_signals unless foreground?
      set_exit_hook
      set_process_title
      start_server
    end

    def start_server
      server = UNIXServer.open(env.socket_name)
      log "started on #{env.socket_name}"
      loop { serve server.accept }
    rescue Interrupt
    end

    def serve(client)
      log "accepted client"
      client.puts env.version

      app_client = client.recv_io
      command    = JSON.load(client.read(client.gets.to_i))

      args, default_rails_env = command.values_at('args', 'default_rails_env')

      if Spring.command?(args.first)
        log "running command #{args.first}"
        client.puts
        client.puts @applications[rails_env_for(args, default_rails_env)].run(app_client)
      else
        log "command not found #{args.first}"
        client.close
      end
    rescue SocketError => e
      raise e unless client.eof?
    ensure
      redirect_output
    end

    def rails_env_for(args, default_rails_env)
      Spring.command(args.first).env(args.drop(1)) || default_rails_env
    end

    # Boot the server into the process group of the current session.
    # This will cause it to be automatically killed once the session
    # ends (i.e. when the user closes their terminal).
    def set_pgid
      pgid = Process.getpgid(Process.getsid)
      Process.setpgid(0, pgid)
    end

    # Ignore SIGINT and SIGQUIT otherwise the user typing ^C or ^\ on the command line
    # will kill the server/application.
    def ignore_signals
      IGNORE_SIGNALS.each { |sig| trap(sig, "IGNORE") }
    end

    def set_exit_hook
      server_pid = Process.pid

      # We don't want this hook to run in any forks of the current process
      at_exit { shutdown if Process.pid == server_pid }
    end

    def shutdown
      log "shutting down"

      [env.socket_path, env.pidfile_path].each do |path|
        if path.exist?
          path.unlink rescue nil
        end
      end

      @applications.values.map { |a| Spring.failsafe_thread { a.stop } }.map(&:join)
    end

    def write_pidfile
      if @pidfile.flock(File::LOCK_EX | File::LOCK_NB)
        @pidfile.truncate(0)
        @pidfile.write("#{Process.pid}\n")
        @pidfile.fsync
      else
        exit 1
      end
    end

    # We need to redirect STDOUT and STDERR, otherwise the server will
    # keep the original FDs open which would break piping. (e.g.
    # `spring rake -T | grep db` would hang forever because the server
    # would keep the stdout FD open.)
    def redirect_output
      [STDOUT, STDERR].each { |stream| stream.reopen(env.log_file) }
    end

    def set_process_title
      ProcessTitleUpdater.run { |distance|
        "spring server | #{env.app_name} | started #{distance} ago"
      }
    end

    private

    def default_env
      Env.new(log_file: default_log_file)
    end

    def default_log_file
      if foreground? && !ENV["SPRING_LOG"]
        $stdout
      else
        nil
      end
    end
  end
end
