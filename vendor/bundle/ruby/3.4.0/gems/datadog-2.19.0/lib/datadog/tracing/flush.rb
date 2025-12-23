# frozen_string_literal: true

module Datadog
  module Tracing
    module Flush
      # Consumes and returns a {TraceSegment} to be flushed, from
      # the provided {TraceSegment}.
      #
      # Only finished spans are consumed. Any spans consumed are
      # removed from +trace_op+ as a side effect. Unfinished spans are
      # unaffected.
      #
      # @abstract
      class Base
        # Consumes and returns a {TraceSegment} to be flushed, from
        # the provided {TraceSegment}.
        #
        # Only finished spans are consumed. Any spans consumed are
        # removed from +trace_op+ as a side effect. Unfinished spans are
        # unaffected.
        #
        # @param [TraceOperation] trace_op
        # @return [TraceSegment] trace to be flushed, or +nil+ if the trace is not finished
        def consume!(trace_op)
          return unless flush?(trace_op)

          get_trace(trace_op)
        end

        # Should we consume spans from the +trace_op+?
        # @abstract
        def flush?(trace_op)
          raise NotImplementedError
        end

        protected

        # Consumes all finished spans from trace.
        # @return [TraceSegment]
        def get_trace(trace_op)
          trace_op.flush! do |spans|
            spans.select! { |span| single_sampled?(span) } unless trace_op.sampled?

            spans
          end
        end

        # Single Span Sampling has chosen to keep this span
        # regardless of the trace-level sampling decision
        def single_sampled?(span)
          span.get_metric(Sampling::Span::Ext::TAG_MECHANISM) == Sampling::Ext::Mechanism::SPAN_SAMPLING_RATE
        end
      end

      # Consumes and returns completed traces (where all spans have finished),
      # if any, from the provided +trace_op+.
      #
      # Spans consumed are removed from +trace_op+ as a side effect.
      class Finished < Base
        # Are all spans finished?
        def flush?(trace_op)
          trace_op && trace_op.finished?
        end
      end

      # Consumes and returns completed or partially completed
      # traces from the provided +trace_op+, if any.
      #
      # Partial trace flushing avoids large traces residing in memory for too long.
      #
      # Partially completed traces, where not all spans have finished,
      # will only be returned if there are at least
      # +@min_spans_for_partial+ finished spans.
      #
      # Spans consumed are removed from +trace_op+ as a side effect.
      class Partial < Base
        # Start flushing partial trace after this many active spans in one trace
        DEFAULT_MIN_SPANS_FOR_PARTIAL_FLUSH = 500

        attr_reader :min_spans_for_partial

        def initialize(options = {})
          super()
          @min_spans_for_partial = options.fetch(:min_spans_before_partial_flush, DEFAULT_MIN_SPANS_FOR_PARTIAL_FLUSH)
        end

        def flush?(trace_op)
          return true if trace_op.finished?
          return false if trace_op.finished_span_count < @min_spans_for_partial

          true
        end
      end
    end
  end
end
