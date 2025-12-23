# frozen_string_literal: true

require_relative '../tracing/trace_digest'

module Datadog
  module OpenTelemetry
    # OpenTelemetry utilities related to the respective Datadog trace.
    module Trace
      class << self
        # Creates a new TraceOperation object that can be attached to a new
        # OpenTelemetry span.
        # If `parent_span` is provided, then that span is set as the currently
        # active parent span.
        #
        # @return [TraceOperation]
        def start_trace_copy(trace, parent_span: nil)
          digest = if parent_span
                     digest_with_parent_span(trace, parent_span)
                   else
                     trace.to_digest
                   end

          # Create a new TraceOperation, attached to the current Datadog Tracer.
          Datadog::Tracing.continue_trace!(digest)
        end

        private

        # Creates a TraceDigest with the active span modified.
        # This supports the implementation of `OpenTelemetry::Trace.context_with_span`,
        # which allows you to specific any span as the arbitrary parent of a new span.
        def digest_with_parent_span(trace, parent_span)
          digest = trace.to_digest

          Tracing::TraceDigest.new(
            span_id: parent_span.id,
            span_name: parent_span.name,
            span_resource: parent_span.resource,
            span_service: parent_span.service,
            span_type: parent_span.type,
            trace_distributed_tags: digest.trace_distributed_tags,
            trace_hostname: digest.trace_hostname,
            trace_id: digest.trace_id,
            trace_name: digest.trace_name,
            trace_origin: digest.trace_origin,
            trace_process_id: digest.trace_process_id,
            trace_resource: digest.trace_resource,
            trace_runtime_id: digest.trace_runtime_id,
            trace_sampling_priority: digest.trace_sampling_priority,
            trace_service: digest.trace_service,
            trace_state: digest.trace_state,
            trace_state_unknown_fields: digest.trace_state_unknown_fields,
            span_remote: digest.span_remote,
          ).freeze
        end
      end
    end
  end
end
