# frozen_string_literal: true

require_relative 'buffer'
require_relative 'pipeline'

module Datadog
  module Tracing
    module Workers
      # Asynchronous worker that executes a +Send()+ operation after given
      # seconds. Under the hood, it uses +Concurrent::TimerTask+ so that the thread
      # will perform a task at regular intervals. The thread can be stopped
      # with the +stop()+ method and can start with the +start()+ method.
      class AsyncTransport
        DEFAULT_BUFFER_MAX_SIZE = 1000
        DEFAULT_FLUSH_INTERVAL = 1
        DEFAULT_TIMEOUT = 5
        BACK_OFF_RATIO = 1.2
        BACK_OFF_MAX = 5
        DEFAULT_SHUTDOWN_TIMEOUT = 1

        attr_reader :trace_buffer, :logger

        def initialize(options = {})
          @transport = options[:transport]

          # Callbacks
          @trace_task = options[:on_trace]

          # Intervals
          interval = options.fetch(:interval, DEFAULT_FLUSH_INTERVAL)
          @flush_interval = interval
          @back_off = interval

          # Buffers
          buffer_size = options.fetch(:buffer_size, DEFAULT_BUFFER_MAX_SIZE)
          @trace_buffer = TraceBuffer.new(buffer_size)

          # Threading
          @shutdown = ConditionVariable.new
          @shutdown_timeout = options.fetch(:shutdown_timeout, DEFAULT_SHUTDOWN_TIMEOUT)
          @mutex = Mutex.new
          @worker = nil
          @run = false

          @logger = options.fetch(:logger)
        end

        # Callback function that process traces and executes the +send_traces()+ method.
        def callback_traces
          return true if @trace_buffer.empty?

          begin
            traces = @trace_buffer.pop
            traces = Pipeline.process!(traces)
            @trace_task.call(traces, @transport) unless @trace_task.nil? || traces.empty?
          rescue StandardError => e
            # ensures that the thread will not die because of an exception.
            # TODO[manu]: findout the reason and reschedule the send if it's not
            # a fatal exception
            logger.warn(
              "Error during traces flush: dropped #{traces.length} items. Cause: #{e} Location: #{Array(e.backtrace).first}"
            )
          end
        end

        # Start the timer execution.
        def start
          @mutex.synchronize do
            return if @run

            @run = true
            logger.debug { "Starting thread for: #{self}" }
            @worker = Thread.new { perform }
            @worker.name = self.class.name
            @worker.thread_variable_set(:fork_safe, true)

            nil
          end
        end

        # Closes all available queues and waits for the trace buffer to flush
        def stop
          @mutex.synchronize do
            return unless @run

            @trace_buffer.close
            @run = false
            @shutdown.signal
          end

          join
          true
        end

        # Block until executor shutdown is complete or until timeout seconds have passed.
        def join
          @worker.join(@shutdown_timeout)
        end

        # Enqueue an item in the trace internal buffer. This operation is thread-safe
        # because uses the +TraceBuffer+ data structure.
        def enqueue_trace(trace)
          return unless trace && !trace.empty?

          @trace_buffer.push(trace)
        end

        private

        alias flush_data callback_traces

        def perform
          loop do
            @back_off = flush_data ? @flush_interval : [@back_off * BACK_OFF_RATIO, BACK_OFF_MAX].min

            @mutex.synchronize do
              return if !@run && @trace_buffer.empty?

              @shutdown.wait(@mutex, @back_off) if @run # do not wait when shutting down
            end
          end
        end
      end
    end
  end
end
