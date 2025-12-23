module ChildProcess
  class AbstractProcess
    POLL_INTERVAL = 0.1

    attr_reader :exit_code

    #
    # Set this to true if you do not care about when or if the process quits.
    #
    attr_accessor :detach

    #
    # Set this to true if you want to write to the process' stdin (process.io.stdin)
    #
    attr_accessor :duplex

    #
    # Modify the child's environment variables
    #
    attr_reader :environment

    #
    # Set the child's current working directory.
    #
    attr_accessor :cwd

    #
    # Set this to true to make the child process the leader of a new process group
    #
    # This can be used to make sure that all grandchildren are killed
    # when the child process dies.
    #
    attr_accessor :leader

    #
    # Create a new process with the given args.
    #
    # @api private
    # @see ChildProcess.build
    #

    def initialize(*args)
      unless args.all? { |e| e.kind_of?(String) }
        raise ArgumentError, "all arguments must be String: #{args.inspect}"
      end

      @args        = args
      @started     = false
      @exit_code   = nil
      @io          = nil
      @cwd         = nil
      @detach      = false
      @duplex      = false
      @leader      = false
      @environment = {}
    end

    #
    # Returns a ChildProcess::AbstractIO subclass to configure the child's IO streams.
    #

    def io
      raise SubclassResponsibility, "io"
    end

    #
    # @return [Integer] the pid of the process after it has started
    #

    def pid
      raise SubclassResponsibility, "pid"
    end

    #
    # Launch the child process
    #
    # @return [AbstractProcess] self
    #

    def start
      launch_process
      @started = true

      self
    end

    #
    # Forcibly terminate the process, using increasingly harsher methods if possible.
    #
    # @param [Integer] timeout (3) Seconds to wait before trying the next method.
    #

    def stop(timeout = 3)
      raise SubclassResponsibility, "stop"
    end

    #
    # Block until the process has been terminated.
    #
    # @return [Integer] The exit status of the process
    #

    def wait
      raise SubclassResponsibility, "wait"
    end

    #
    # Did the process exit?
    #
    # @return [Boolean]
    #

    def exited?
      raise SubclassResponsibility, "exited?"
    end

    #
    # Has the process started?
    #
    # @return [Boolean]
    #

    def started?
      @started
    end

    #
    # Is this process running?
    #
    # @return [Boolean]
    #

    def alive?
      started? && !exited?
    end

    #
    # Returns true if the process has exited and the exit code was not 0.
    #
    # @return [Boolean]
    #

    def crashed?
      exited? && @exit_code != 0
    end

    #
    # Wait for the process to exit, raising a ChildProcess::TimeoutError if
    # the timeout expires.
    #

    def poll_for_exit(timeout)
      log "polling #{timeout} seconds for exit"

      end_time = Time.now + timeout
      until (ok = exited?) || Time.now > end_time
        sleep POLL_INTERVAL
      end

      unless ok
        raise TimeoutError, "process still alive after #{timeout} seconds"
      end
    end

    private

    def launch_process
      raise SubclassResponsibility, "launch_process"
    end

    def detach?
      @detach
    end

    def duplex?
      @duplex
    end

    def leader?
      @leader
    end

    def log(*args)
      ChildProcess.logger.debug "#{self.inspect} : #{args.inspect}"
    end

    def assert_started
      raise Error, "process not started" unless started?
    end

  end # AbstractProcess
end # ChildProcess
