require "timeout"
require "benchmark"

module MiniMagick
  ##
  # Sends commands to the shell (more precisely, it sends commands directly to
  # the operating system).
  #
  # @private
  #
  class Shell

    def run(command, options = {})
      stdout, stderr, status = execute(command, stdin: options[:stdin])

      if status != 0 && options.fetch(:whiny, MiniMagick.whiny)
        fail MiniMagick::Error, "`#{command.join(" ")}` failed with status: #{status} and error:\n#{stderr}"
      end

      $stderr.print(stderr) unless options[:stderr] == false

      [stdout, stderr, status]
    end

    def execute(command, options = {})
      stdout, stderr, status =
        log(command.join(" ")) do
          send("execute_#{MiniMagick.shell_api.tr("-", "_")}", command, options)
        end

      [stdout, stderr, status.exitstatus]
    rescue Errno::ENOENT, IOError
      ["", "executable not found: \"#{command.first}\"", 127]
    end

    private

    def execute_open3(command, options = {})
      require "open3"

      # We would ideally use Open3.capture3, but it wouldn't allow us to
      # terminate the command after timing out.
      Open3.popen3(*command) do |in_w, out_r, err_r, thread|
        [in_w, out_r, err_r].each(&:binmode)
        stdout_reader = Thread.new { out_r.read }
        stderr_reader = Thread.new { err_r.read }
        begin
          in_w.write options[:stdin].to_s
        rescue Errno::EPIPE
        end
        in_w.close

        unless thread.join(MiniMagick.timeout)
          Process.kill("TERM", thread.pid) rescue nil
          Process.waitpid(thread.pid)      rescue nil
          raise Timeout::Error, "MiniMagick command timed out: #{command}"
        end

        [stdout_reader.value, stderr_reader.value, thread.value]
      end
    end

    def execute_posix_spawn(command, options = {})
      require "posix-spawn"
      child = POSIX::Spawn::Child.new(*command, input: options[:stdin].to_s, timeout: MiniMagick.timeout)
      [child.out, child.err, child.status]
    rescue POSIX::Spawn::TimeoutExceeded
      raise Timeout::Error, "MiniMagick command timed out: #{command}"
    end

    def log(command, &block)
      value = nil
      duration = Benchmark.realtime { value = block.call }
      MiniMagick.logger.debug "[%.2fs] %s" % [duration, command]
      value
    end

  end
end
