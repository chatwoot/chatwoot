require_relative 'abstract_process'

module ChildProcess
  class ProcessSpawnProcess < AbstractProcess
    attr_reader :pid

    def exited?
      return true if @exit_code

      assert_started
      pid, status = ::Process.waitpid2(@pid, ::Process::WNOHANG | ::Process::WUNTRACED)
      pid = nil if pid == 0 # may happen on jruby

      log(:pid => pid, :status => status)

      if pid
        set_exit_code(status)
      end

      !!pid
    rescue Errno::ECHILD
      # may be thrown for detached processes
      true
    end

    def wait
      assert_started

      if exited?
        exit_code
      else
        _, status = ::Process.waitpid2(@pid)

        set_exit_code(status)
      end
    end

    private

    def launch_process
      environment = {}
      @environment.each_pair do |key, value|
        key = key.to_s
        value = value.nil? ? nil : value.to_s

        if key.include?("\0") || key.include?("=") || value.to_s.include?("\0")
          raise InvalidEnvironmentVariable, "#{key.inspect} => #{value.to_s.inspect}"
        end
        environment[key] = value
      end

      options = {}

      options[:out] = io.stdout ? io.stdout.fileno : File::NULL
      options[:err] = io.stderr ? io.stderr.fileno : File::NULL

      if duplex?
        reader, writer = ::IO.pipe
        options[:in] = reader.fileno
        unless ChildProcess.windows?
          options[writer.fileno] = :close
        end
      end

      if leader?
        if ChildProcess.windows?
          options[:new_pgroup] = true
        else
          options[:pgroup] = true
        end
      end

      options[:chdir] = @cwd if @cwd

      if @args.size == 1
        # When given a single String, Process.spawn would think it should use the shell
        # if there is any special character in it. However,  ChildProcess should never
        # use the shell. So we use the [cmdname, argv0] form to force no shell.
        arg = @args[0]
        args = [[arg, arg]]
      else
        args = @args
      end

      begin
        @pid = ::Process.spawn(environment, *args, options)
      rescue SystemCallError => e
        raise LaunchError, e.message
      end

      if duplex?
        io._stdin = writer
        reader.close
      end

      ::Process.detach(@pid) if detach?
    end

    def set_exit_code(status)
      @exit_code = status.exitstatus || status.termsig
    end

    def send_term
      send_signal 'TERM'
    end

    def send_kill
      send_signal 'KILL'
    end

    def send_signal(sig)
      assert_started

      log "sending #{sig}"
      if leader?
        if ChildProcess.unix?
          ::Process.kill sig, -@pid # negative pid == process group
        else
          output = `taskkill /F /T /PID #{@pid}`
          log output
        end
      else
        ::Process.kill sig, @pid
      end
    end
  end
end
