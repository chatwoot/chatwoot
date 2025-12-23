require "foreman"
require "foreman/env"
require "foreman/process"
require "foreman/procfile"
require "tempfile"
require "fileutils"
require "thread"

class Foreman::Engine

  # The signals that the engine cares about.
  #
  HANDLED_SIGNALS = [ :TERM, :INT, :HUP, :USR1, :USR2 ]

  attr_reader :env
  attr_reader :options
  attr_reader :processes

  # Create an +Engine+ for running processes
  #
  # @param [Hash] options
  #
  # @option options [String] :formation (all=1)    The process formation to use
  # @option options [Fixnum] :port      (5000)     The base port to assign to processes
  # @option options [String] :root      (Dir.pwd)  The root directory from which to run processes
  #
  def initialize(options={})
    @options = options.dup

    @options[:formation] ||= "all=1"
    @options[:timeout] ||= 5

    @env       = {}
    @mutex     = Mutex.new
    @names     = {}
    @processes = []
    @running   = {}
    @readers   = {}
    @shutdown  = false

    # Self-pipe for deferred signal-handling (ala djb: http://cr.yp.to/docs/selfpipe.html)
    reader, writer       = create_pipe
    reader.close_on_exec = true if reader.respond_to?(:close_on_exec)
    writer.close_on_exec = true if writer.respond_to?(:close_on_exec)
    @selfpipe            = { :reader => reader, :writer => writer }

    # Set up a global signal queue
    # http://blog.rubybestpractices.com/posts/ewong/016-Implementing-Signal-Handlers.html
    Thread.main[:signal_queue] = []
  end

  # Start the processes registered to this +Engine+
  #
  def start
    register_signal_handlers
    startup
    spawn_processes
    watch_for_output
    sleep 0.1
    wait_for_shutdown_or_child_termination
    shutdown
    exit(@exitstatus) if @exitstatus
  end

  # Set up deferred signal handlers
  #
  def register_signal_handlers
    HANDLED_SIGNALS.each do |sig|
      if ::Signal.list.include? sig.to_s
        trap(sig) { Thread.main[:signal_queue] << sig ; notice_signal }
      end
    end
  end

  # Unregister deferred signal handlers
  #
  def restore_default_signal_handlers
    HANDLED_SIGNALS.each do |sig|
      trap(sig, :DEFAULT) if ::Signal.list.include? sig.to_s
    end
  end

  # Wake the main thread up via the selfpipe when there's a signal
  #
  def notice_signal
    @selfpipe[:writer].write_nonblock( '.' )
  rescue Errno::EAGAIN
    # Ignore writes that would block
  rescue Errno::EINTR
    # Retry if another signal arrived while writing
    retry
  end

  # Invoke the real handler for signal +sig+. This shouldn't be called directly
  # by signal handlers, as it might invoke code which isn't re-entrant.
  #
  # @param [Symbol] sig  the name of the signal to be handled
  #
  def handle_signal(sig)
    case sig
    when :TERM
      handle_term_signal
    when :INT
      handle_interrupt
    when :HUP
      handle_hangup
    when *HANDLED_SIGNALS
      handle_signal_forward(sig)
    else
      system "unhandled signal #{sig}"
    end
  end

  # Handle a TERM signal
  #
  def handle_term_signal
    system "SIGTERM received, starting shutdown"
    @shutdown = true
  end

  # Handle an INT signal
  #
  def handle_interrupt
    system "SIGINT received, starting shutdown"
    @shutdown = true
  end

  # Handle a HUP signal
  #
  def handle_hangup
    system "SIGHUP received, starting shutdown"
    @shutdown = true
  end

  def handle_signal_forward(signal)
    system "#{signal} received, forwarding it to children"
    kill_children signal
  end

  # Register a process to be run by this +Engine+
  #
  # @param [String] name     A name for this process
  # @param [String] command  The command to run
  # @param [Hash]   options
  #
  # @option options [Hash] :env  A custom environment for this process
  #
  def register(name, command, options={})
    options[:env] ||= env
    options[:cwd] ||= File.dirname(command.split(" ").first)
    process = Foreman::Process.new(command, options)
    @names[process] = name
    @processes << process
  end

  # Clear the processes registered to this +Engine+
  #
  def clear
    @names     = {}
    @processes = []
  end

  # Register processes by reading a Procfile
  #
  # @param [String] filename  A Procfile from which to read processes to register
  #
  def load_procfile(filename)
    options[:root] ||= File.dirname(filename)
    Foreman::Procfile.new(filename).entries do |name, command|
      register name, command, :cwd => options[:root]
    end
    self
  end

  # Load a .env file into the +env+ for this +Engine+
  #
  # @param [String] filename  A .env file to load into the environment
  #
  def load_env(filename)
    Foreman::Env.new(filename).entries do |name, value|
      @env[name] = value
    end
  end

  # Send a signal to all processes started by this +Engine+
  #
  # @param [String] signal  The signal to send to each process
  #
  def kill_children(signal="SIGTERM")
    if Foreman.windows?
      @running.each do |pid, (process, index)|
        system "sending #{signal} to #{name_for(pid)} at pid #{pid}"
        begin
          Process.kill(signal, pid)
        rescue Errno::ESRCH, Errno::EPERM
        end
      end
    else
      begin
        pids = @running.keys.compact
        Process.kill signal, *pids unless pids.empty?
      rescue Errno::ESRCH, Errno::EPERM
      end
    end
  end

  # Send a signal to the whole process group.
  #
  # @param [String] signal  The signal to send
  #
  def killall(signal="SIGTERM")
    if Foreman.windows?
      kill_children(signal)
    else
      begin
        Process.kill "-#{signal}", Process.pid
      rescue Errno::ESRCH, Errno::EPERM
      end
    end
  end

  # Get the process formation
  #
  # @returns [Fixnum]  The formation count for the specified process
  #
  def formation
    @formation ||= parse_formation(options[:formation])
  end

  # List the available process names
  #
  # @returns [Array]  A list of process names
  #
  def process_names
    @processes.map { |p| @names[p] }
  end

  # Get the +Process+ for a specifid name
  #
  # @param [String] name  The process name
  #
  # @returns [Foreman::Process]  The +Process+ for the specified name
  #
  def process(name)
    @names.invert[name]
  end

  # Yield each +Process+ in order
  #
  def each_process
    process_names.each do |name|
      yield name, process(name)
    end
  end

  # Get the root directory for this +Engine+
  #
  # @returns [String]  The root directory
  #
  def root
    File.expand_path(options[:root] || Dir.pwd)
  end

  # Get the port for a given process and offset
  #
  # @param [Foreman::Process] process   A +Process+ associated with this engine
  # @param [Fixnum]           instance  The instance of the process
  #
  # @returns [Fixnum] port  The port to use for this instance of this process
  #
  def port_for(process, instance, base=nil)
    if base
      base + (@processes.index(process.process) * 100) + (instance - 1)
    else
      base_port + (@processes.index(process) * 100) + (instance - 1)
    end
  end

  # Get the base port for this foreman instance
  #
  # @returns [Fixnum] port  The base port
  #
  def base_port
    (options[:port] || env["PORT"] || ENV["PORT"] || 5000).to_i
  end

  # deprecated
  def environment
    env
  end

private

### Engine API ######################################################

  def startup
    raise TypeError, "must use a subclass of Foreman::Engine"
  end

  def output(name, data)
    raise TypeError, "must use a subclass of Foreman::Engine"
  end

  def shutdown
    raise TypeError, "must use a subclass of Foreman::Engine"
  end

## Helpers ##########################################################

  def create_pipe
    IO.method(:pipe).arity.zero? ? IO.pipe : IO.pipe("BINARY")
  end

  def name_for(pid)
    process, index = @running[pid]
    name_for_index(process, index)
  end

  def name_for_index(process, index)
    [ @names[process], index.to_s ].compact.join(".")
  end

  def parse_formation(formation)
    pairs = formation.to_s.gsub(/\s/, "").split(",")

    pairs.inject(Hash.new(0)) do |ax, pair|
      process, amount = pair.split("=")
      process == "all" ? ax.default = amount.to_i : ax[process] = amount.to_i
      ax
    end
  end

  def output_with_mutex(name, message)
    @mutex.synchronize do
      output name, message
    end
  end

  def system(message)
    output_with_mutex "system", message
  end

  def termination_message_for(status)
    if status.exited?
      "exited with code #{status.exitstatus}"
    elsif status.signaled?
      "terminated by SIG#{Signal.list.invert[status.termsig]}"
    else
      "died a mysterious death"
    end
  end

  def flush_reader(reader)
    until reader.eof?
      data = reader.gets
      output_with_mutex name_for(@readers.key(reader)), data
    end
  end

## Engine ###########################################################

  def spawn_processes
    @processes.each do |process|
      1.upto(formation[@names[process]]) do |n|
        reader, writer = create_pipe
        begin
          pid = process.run(:output => writer, :env => {
            "PORT" => port_for(process, n).to_s,
            "PS" => name_for_index(process, n)
          })
          writer.puts "started with pid #{pid}"
        rescue Errno::ENOENT
          writer.puts "unknown command: #{process.command}"
        end
        @running[pid] = [process, n]
        @readers[pid] = reader
      end
    end
  end

  def read_self_pipe
    @selfpipe[:reader].read_nonblock(11)
  rescue Errno::EAGAIN, Errno::EINTR, Errno::EBADF, Errno::EWOULDBLOCK
    # ignore
  end

  def handle_signals
    while sig = Thread.main[:signal_queue].shift
      self.handle_signal(sig)
    end
  end

  def handle_io(readers)
    readers.each do |reader|
      next if reader == @selfpipe[:reader]

      if reader.eof?
        @readers.delete_if { |key, value| value == reader }
      else
        data = reader.gets
        output_with_mutex name_for(@readers.invert[reader]), data
      end
    end
  end

  def watch_for_output
    Thread.new do
      begin
        loop do
          io = IO.select([@selfpipe[:reader]] + @readers.values, nil, nil, 30)
          read_self_pipe
          handle_signals
          handle_io(io ? io.first : [])
        end
      rescue Exception => ex
        puts ex.message
        puts ex.backtrace
      end
    end
  end

  def wait_for_shutdown_or_child_termination
    loop do
      # Stop if it is time to shut down (asked via a signal)
      break if @shutdown

      # Stop if any of the children died
      break if check_for_termination

      # Sleep for a moment and do not blow up if any signals are coming our way
      begin
        sleep(1)
      rescue Exception
        # noop
      end
    end

    # Ok, we have exited from the main loop, time to shut down gracefully
    terminate_gracefully
  end

  def check_for_termination
    # Check if any of the children have died off
    pid, status = begin
      Process.wait2(-1, Process::WNOHANG)
    rescue Errno::ECHILD
      return nil
    end

    # record the exit status
    @exitstatus ||= status.exitstatus if status

    # If no childred have died, nothing to do here
    return nil unless pid

    # Log the information about the process that exited
    output_with_mutex name_for(pid), termination_message_for(status)

    # Delete it from the list of running processes and return its pid
    @running.delete(pid)
    return pid
  end

  def terminate_gracefully
    restore_default_signal_handlers

    # Tell all children to stop gracefully
    if Foreman.windows?
      system  "sending SIGKILL to all processes"
      kill_children "SIGKILL"
    else
      system  "sending SIGTERM to all processes"
      kill_children "SIGTERM"
    end

    # Wait for all children to stop or until the time comes to kill them all
    start_time = Time.now
    while Time.now - start_time <= options[:timeout]
      return if @running.empty?
      check_for_termination

      # Sleep for a moment and do not blow up if more signals are coming our way
      begin
        sleep(0.1)
      rescue Exception
        # noop
      end
    end

    # Ok, we have no other option than to kill all of our children
    system  "sending SIGKILL to all processes"
    kill_children "SIGKILL"
  end
end
