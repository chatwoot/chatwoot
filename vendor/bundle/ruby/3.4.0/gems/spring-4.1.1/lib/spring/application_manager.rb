module Spring
  class ApplicationManager
    attr_reader :pid, :child, :app_env, :spring_env, :status

    def initialize(app_env, spring_env)
      @app_env    = app_env
      @spring_env = spring_env
      @mutex      = Mutex.new
      @state      = :running
      @pid        = nil
    end

    def log(message)
      spring_env.log "[application_manager:#{app_env}] #{message}"
    end

    # We're not using @mutex.synchronize to avoid the weird "<internal:prelude>:10"
    # line which messes with backtraces in e.g. rspec
    def synchronize
      @mutex.lock
      yield
    ensure
      @mutex.unlock
    end

    def start
      start_child
    end

    def restart
      return if @state == :stopping
      start_child(true)
    end

    def alive?
      @pid
    end

    def with_child
      synchronize do
        if alive?
          begin
            yield
          rescue Errno::ECONNRESET, Errno::EPIPE
            # The child has died but has not been collected by the wait thread yet,
            # so start a new child and try again.
            log "child dead; starting"
            start
            yield
          end
        else
          log "child not running; starting"
          start
          yield
        end
      end
    end

    # Returns the pid of the process running the command, or nil if the application process died.
    def run(client)
      with_child do
        child.send_io client
        child.gets or raise Errno::EPIPE
      end

      pid = child.gets.to_i

      unless pid.zero?
        log "got worker pid #{pid}"
        pid
      end
    rescue Errno::ECONNRESET, Errno::EPIPE => e
      log "#{e} while reading from child; returning no pid"
      nil
    ensure
      client.close
    end

    def stop
      log "stopping"
      @state = :stopping

      if pid
        Process.kill('TERM', pid)
        Process.wait(pid)
      end
    rescue Errno::ESRCH, Errno::ECHILD
      # Don't care
    end

    private

    def start_child(preload = false)
      @child, child_socket = UNIXSocket.pair

      Bundler.with_original_env do
        bundler_dir = File.expand_path("../..", $LOADED_FEATURES.grep(/bundler\/setup\.rb$/).first)
        @pid = Process.spawn(
          {
            "RAILS_ENV"           => app_env,
            "RACK_ENV"            => app_env,
            "SPRING_ORIGINAL_ENV" => JSON.dump(Spring::ORIGINAL_ENV),
            "SPRING_PRELOAD"      => preload ? "1" : "0"
          },
          "ruby",
          *(bundler_dir != RbConfig::CONFIG["rubylibdir"] ? ["-I", bundler_dir] : []),
          "-I", File.expand_path("../..", __FILE__),
          "-e", "require 'spring/application/boot'",
          3 => child_socket,
          4 => spring_env.log_file,
        )
      end

      start_wait_thread(pid, child) if child.gets
      child_socket.close
    end

    def start_wait_thread(pid, child)
      Process.detach(pid)

      Spring.failsafe_thread {
        # The recv can raise an ECONNRESET, killing the thread, but that's ok
        # as if it does we're no longer interested in the child
        loop do
          IO.select([child])
          break if child.recv(1, Socket::MSG_PEEK).empty?
          sleep 0.01
        end

        log "child #{pid} shutdown"

        synchronize {
          if @pid == pid
            @pid = nil
            restart
          end
        }
      }
    end
  end
end
