# frozen_string_literal: true

require 'set'
require_relative 'span_processor'

module Datadog
  module Tracing
    module Pipeline
      # SpanFilter implements a processor that filters entire span subtrees
      # This processor executes the configured `operation` for each {Datadog::Tracing::Span}
      # in a {Datadog::Tracing::TraceSegment}.
      #
      # If `operation` returns a truthy value for a span, that span is dropped,
      # otherwise the span is kept.
      #
      # @public_api
      class SpanFilter < SpanProcessor
        # NOTE: This SpanFilter implementation only handles traces in which child spans appear
        # before parent spans in the trace array. If in the future child spans can be after
        # parent spans, then the code below will need to be updated.
        # @!visibility private
        def call(trace)
          deleted = Set.new

          span_count = trace.spans.length
          trace.spans.reverse_each.with_index do |span, i|
            should_delete = deleted.include?(span.parent_id) || drop_it?(span)

            if should_delete
              deleted << span.id
              trace.spans.delete_at(span_count - 1 - i)
            end
          end

          trace
        end

        private

        def drop_it?(span)
          @operation.call(span) rescue false
        end
      end
    end
  end
end
