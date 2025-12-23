# frozen_string_literal: true

require_relative 'event'
require_relative 'runtime/metrics'
require_relative 'workers'

require_relative 'transport/http'

module Datadog
  module Tracing
    # Processor that sends traces and metadata to the agent
    # DEV: Our goal is for {Datadog::Tracing::Workers::TraceWriter} to replace this class in the future
    # @public_api
    class Writer
      attr_reader \
        :logger,
        :transport,
        :worker,
        :events,
        :agent_settings

      def initialize(options = {})
        @logger = options[:logger] || Datadog.logger

        # writer and transport parameters
        @buff_size = options.fetch(:buffer_size, Workers::AsyncTransport::DEFAULT_BUFFER_MAX_SIZE)
        @flush_interval = options.fetch(:flush_interval, Workers::AsyncTransport::DEFAULT_FLUSH_INTERVAL)
        transport_options = options.fetch(:transport_options, {})
        @agent_settings = options[:agent_settings]

        # transport and buffers
        @transport = options.fetch(:transport) do
          Transport::HTTP.default(agent_settings: agent_settings, logger: logger, **transport_options)
        end

        @shutdown_timeout = options.fetch(:shutdown_timeout, Workers::AsyncTransport::DEFAULT_SHUTDOWN_TIMEOUT)

        # handles the thread creation after an eventual fork
        @mutex_after_fork = Mutex.new
        @pid = nil

        @traces_flushed = 0

        # one worker for traces
        @worker = nil

        # Once stopped, this writer instance cannot be restarted.
        # This allow for graceful shutdown, while preventing
        # the host application from inadvertently start new
        # threads during shutdown.
        @stopped = false

        # Callback handler
        @events = Events.new
      end

      # Explicitly starts the {Writer}'s internal worker.
      #
      # The {Writer} is also automatically started when necessary during calls to {.write}.
      def start
        @mutex_after_fork.synchronize do
          return false if @stopped

          pid = Process.pid
          return if @worker && pid == @pid

          @pid = pid

          start_worker
          true
        end
      end

      # Gracefully shuts down this writer.
      #
      # Once stopped methods calls won't fail, but
      # no internal work will be performed.
      #
      # It is not possible to restart a stopped writer instance.
      def stop
        @mutex_after_fork.synchronize { stop_worker }
      end

      # flush spans to the trace-agent, handles spans only
      # @!visibility private
      def send_spans(traces, transport)
        return true if traces.empty?

        # Send traces and get responses
        responses = transport.send_traces(traces)

        # Tally up successful flushes
        responses.reject { |x| x.internal_error? || x.server_error? }.each do |response|
          @traces_flushed += response.trace_count
        end

        events.after_send.publish(self, responses)

        # Return if server error occurred.
        !responses.find(&:server_error?)
      end

      # enqueue the trace for submission to the API
      def write(trace)
        # In multiprocess environments, the main process initializes the +Writer+ instance and if
        # the process forks (i.e. a web server like Unicorn or Puma with multiple workers) the new
        # processes will share the same +Writer+ until the first write (COW). Because of that,
        # each process owns a different copy of the +@buffer+ after each write and so the
        # +AsyncTransport+ will not send data to the trace agent.
        #
        # This check ensures that if a process doesn't own the current +Writer+, async workers
        # will be initialized again (but only once for each process).
        start if @worker.nil? || @pid != Process.pid

        # TODO: Remove this, and have the tracer pump traces directly to runtime metrics
        #       instead of working through the trace writer.
        # Associate trace with runtime metrics
        Runtime::Metrics.associate_trace(trace)

        worker_local = @worker

        if worker_local
          worker_local.enqueue_trace(trace)
        elsif !@stopped
          logger.debug('Writer either failed to start or was stopped before #write could complete')
        end
      end

      # stats returns a dictionary of stats about the writer.
      def stats
        {
          traces_flushed: @traces_flushed,
          transport: @transport.stats
        }
      end

      # Callback behavior
      class Events
        attr_reader \
          :after_send

        def initialize
          @after_send = AfterSend.new
        end

        # Triggered after the writer sends traces through the transport.
        # Provides the Writer instance and transport response list to the callback.
        class AfterSend < Tracing::Event
          def initialize
            super(:after_send)
          end
        end
      end

      private

      # spawns a worker for spans; they share the same transport which is thread-safe
      # @!visibility private
      def start_worker
        @trace_handler = ->(items, transport) { send_spans(items, transport) }
        @worker = Workers::AsyncTransport.new(
          transport: @transport,
          buffer_size: @buff_size,
          on_trace: @trace_handler,
          interval: @flush_interval,
          shutdown_timeout: @shutdown_timeout,
          logger: logger,
        )

        @worker.start
      end

      def stop_worker
        @stopped = true

        return if @worker.nil?

        @worker.stop
        @worker = nil

        true
      end

      def reset_stats!
        @traces_flushed = 0
        @transport.stats.reset!
      end
    end
  end
end
