# frozen_string_literal: true

require_relative '../core/environment/ext'
require_relative '../core/buffer/thread_safe'
require_relative '../core/buffer/cruby'
require_relative '../core/diagnostics/health'

module Datadog
  module Tracing
    # Health metrics for trace buffers.
    module MeasuredBuffer
      def initialize(*_)
        super

        @buffer_accepted = 0
        @buffer_accepted_lengths = 0
        @buffer_dropped = 0
        @buffer_spans = 0
      end

      def add!(trace)
        super

        # Emit health metrics
        measure_accept(trace)
      end

      def add_all!(traces)
        super

        # Emit health metrics
        traces.each { |trace| measure_accept(trace) }
      end

      def replace!(trace)
        discarded_trace = super

        # Emit health metrics
        measure_accept(trace)
        measure_drop(discarded_trace) if discarded_trace

        discarded_trace
      end

      # Stored traces are returned and the local buffer is reset.
      def drain!
        traces = super
        measure_pop(traces)
        traces
      end

      def measure_accept(trace)
        @buffer_accepted += 1
        @buffer_accepted_lengths += trace.length

        @buffer_spans += trace.length
      rescue StandardError => e
        Datadog.logger.debug(
          "Failed to measure queue accept. Cause: #{e.class.name} #{e.message} Source: #{Array(e.backtrace).first}"
        )
      end

      def measure_drop(trace)
        @buffer_dropped += 1

        @buffer_spans -= trace.length
      rescue StandardError => e
        Datadog.logger.debug(
          "Failed to measure queue drop. Cause: #{e.class.name} #{e.message} Source: #{Array(e.backtrace).first}"
        )
      end

      def measure_pop(traces)
        # Accepted, cumulative totals
        Datadog.health_metrics.queue_accepted(@buffer_accepted)
        Datadog.health_metrics.queue_accepted_lengths(@buffer_accepted_lengths)

        # Dropped, cumulative totals
        Datadog.health_metrics.queue_dropped(@buffer_dropped)
        # TODO: are we missing a +queue_dropped_lengths+ metric?

        # Queue gauges, current values
        Datadog.health_metrics.queue_max_length(@max_size)
        Datadog.health_metrics.queue_spans(@buffer_spans)
        Datadog.health_metrics.queue_length(traces.length)

        # Reset aggregated metrics
        @buffer_accepted = 0
        @buffer_accepted_lengths = 0
        @buffer_dropped = 0
        @buffer_spans = 0
      rescue StandardError => e
        Datadog.logger.debug(
          "Failed to measure queue. Cause: #{e.class.name} #{e.message} Source: #{Array(e.backtrace).first}"
        )
      end
    end

    # Trace buffer that stores application traces, has a maximum size, and
    # can be safely used concurrently on any environment.
    #
    # @see Datadog::Core::Buffer::ThreadSafe
    class ThreadSafeTraceBuffer < Core::Buffer::ThreadSafe
      prepend MeasuredBuffer
    end

    # Trace buffer that stores application traces, has a maximum size, and
    # can be safely used concurrently with CRuby.
    #
    # @see Datadog::Core::Buffer::CRuby
    class CRubyTraceBuffer < Core::Buffer::CRuby
      prepend MeasuredBuffer
    end

    # Trace buffer that stores application traces. The buffer has a maximum size and when
    # the buffer is full, a random trace is discarded. This class is thread-safe and is used
    # automatically by the ``Tracer`` instance when a ``Span`` is finished.
    #
    # We choose the default TraceBuffer implementation for current platform dynamically here.
    #
    # TODO We should restructure this module, so that classes are not declared at top-level ::Datadog.
    # TODO Making such a change is potentially breaking for users manually configuring the tracer.
    TraceBuffer = if Core::Environment::Ext::RUBY_ENGINE == 'ruby'
                    CRubyTraceBuffer
                  else
                    ThreadSafeTraceBuffer
                  end
  end
end
