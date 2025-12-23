# frozen_string_literal: true

module Datadog
  module Tracing
    module Pipeline
      # This processor executes the configured `operation` for each {Datadog::Tracing::Span}
      # in a {Datadog::Tracing::TraceSegment}.
      #
      # @public_api
      class SpanProcessor
        # You can either provide an `operation` object or a block to this method.
        #
        # Both have the same semantics as `operation`.
        # `operation` is used if both `operation` and a block are present.
        #
        # @param [#call(Datadog::Tracing::Span)] operation a callable that can modify the span.
        def initialize(operation = nil, &block)
          callable = operation || block

          raise(ArgumentError) unless callable.respond_to?(:call)

          @operation = operation || block
        end

        # Invokes `operation#call` for each spans in the `trace` argument.
        # @param [Datadog::Tracing::TraceSegment] trace a trace segment.
        # @return [Datadog::Tracing::TraceSegment] the `trace` provided as an argument.
        # @!visibility private
        def call(trace)
          trace.spans.each do |span|
            @operation.call(span) rescue next
          end

          trace
        end
      end
    end
  end
end
