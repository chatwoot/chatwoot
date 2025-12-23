# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2011-2017, by Tony Arcieri.
# Copyright, 2012, by Logan Bowers.
# Copyright, 2013, by Sadayuki Furuhashi.
# Copyright, 2013, by Stephen von Takach.
# Copyright, 2013, by Tim Carey-Smith.
# Copyright, 2013, by Ravil Bayramgalin.
# Copyright, 2014, by Sergey Avseyev.
# Copyright, 2014, by John Thornton.
# Copyright, 2015, by Vladimir Kochnev.
# Copyright, 2015, by Upekshe Jayasekera.
# Copyright, 2019-2020, by Gregory Longtin.
# Copyright, 2020-2021, by Joao Fernandes.
# Copyright, 2023, by Samuel Williams.

require "set"

module NIO
  # Selectors monitor IO objects for events of interest
  class Selector
    # Return supported backends as symbols
    #
    # See `#backend` method definition for all possible backends
    def self.backends
      [:ruby]
    end

    # Create a new NIO::Selector
    def initialize(backend = :ruby)
      raise ArgumentError, "unsupported backend: #{backend}" unless [:ruby, nil].include?(backend)

      @selectables = {}
      @lock = Mutex.new

      # Other threads can wake up a selector
      @wakeup, @waker = IO.pipe
      @closed = false
    end

    # Return a symbol representing the backend I/O multiplexing mechanism used.
    # Supported backends are:
    # * :ruby     - pure Ruby (i.e IO.select)
    # * :java     - Java NIO on JRuby
    # * :epoll    - libev w\ Linux epoll
    # * :poll     - libev w\ POSIX poll
    # * :kqueue   - libev w\ BSD kqueue
    # * :select   - libev w\ SysV select
    # * :port     - libev w\ I/O completion ports
    # * :linuxaio - libev w\ Linux AIO io_submit (experimental)
    # * :io_uring - libev w\ Linux io_uring (experimental)
    # * :unknown  - libev w\ unknown backend
    def backend
      :ruby
    end

    # Register interest in an IO object with the selector for the given types
    # of events. Valid event types for interest are:
    # * :r - is the IO readable?
    # * :w - is the IO writeable?
    # * :rw - is the IO either readable or writeable?
    def register(io, interest)
      unless defined?(::OpenSSL) && io.is_a?(::OpenSSL::SSL::SSLSocket)
        io = IO.try_convert(io)
      end

      @lock.synchronize do
        raise IOError, "selector is closed" if closed?

        monitor = @selectables[io]
        raise ArgumentError, "already registered as #{monitor.interests.inspect}" if monitor

        monitor = Monitor.new(io, interest, self)
        @selectables[monitor.io] = monitor

        monitor
      end
    end

    # Deregister the given IO object from the selector
    def deregister(io)
      @lock.synchronize do
        monitor = @selectables.delete IO.try_convert(io)
        monitor.close(false) if monitor && !monitor.closed?
        monitor
      end
    end

    # Is the given IO object registered with the selector?
    def registered?(io)
      @lock.synchronize { @selectables.key? io }
    end

    # Select which monitors are ready
    def select(timeout = nil)
      selected_monitors = Set.new

      @lock.synchronize do
        readers = [@wakeup]
        writers = []

        @selectables.each do |io, monitor|
          readers << io if monitor.interests == :r || monitor.interests == :rw
          writers << io if monitor.interests == :w || monitor.interests == :rw
          monitor.readiness = nil
        end

        ready_readers, ready_writers = Kernel.select(readers, writers, [], timeout)
        return unless ready_readers # timeout

        ready_readers.each do |io|
          if io == @wakeup
            # Clear all wakeup signals we've received by reading them
            # Wakeups should have level triggered behavior
            @wakeup.read(@wakeup.stat.size)
          else
            monitor = @selectables[io]
            monitor.readiness = :r
            selected_monitors << monitor
          end
        end

        ready_writers.each do |io|
          monitor = @selectables[io]
          monitor.readiness = monitor.readiness == :r ? :rw : :w
          selected_monitors << monitor
        end
      end

      if block_given?
        selected_monitors.each { |m| yield m }
        selected_monitors.size
      else
        selected_monitors.to_a
      end
    end

    # Wake up a thread that's in the middle of selecting on this selector, if
    # any such thread exists.
    #
    # Invoking this method more than once between two successive select calls
    # has the same effect as invoking it just once. In other words, it provides
    # level-triggered behavior.
    def wakeup
      # Send the selector a signal in the form of writing data to a pipe
      begin
        @waker.write_nonblock "\0"
      rescue IO::WaitWritable
        # This indicates the wakeup pipe is full, which means the other thread
        # has already received many wakeup calls, but not processed them yet.
        # The other thread will completely drain this pipe when it wakes up,
        # so it's ok to ignore this exception if it occurs: we know the other
        # thread has already been signaled to wake up
      end

      nil
    end

    # Close this selector and free its resources
    def close
      @lock.synchronize do
        return if @closed

        begin
          @wakeup.close
        rescue IOError
        end

        begin
          @waker.close
        rescue IOError
        end

        @closed = true
      end
    end

    # Is this selector closed?
    def closed?
      @closed
    end

    def empty?
      @selectables.empty?
    end
  end
end
