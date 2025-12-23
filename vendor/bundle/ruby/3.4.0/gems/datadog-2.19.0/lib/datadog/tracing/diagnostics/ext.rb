# frozen_string_literal: true

module Datadog
  module Tracing
    module Diagnostics
      # @public_api
      module Ext
        # Health
        module Health
          # Metrics
          module Metrics
            METRIC_API_ERRORS = 'datadog.tracer.api.errors'
            METRIC_API_REQUESTS = 'datadog.tracer.api.requests'
            METRIC_API_RESPONSES = 'datadog.tracer.api.responses'
            METRIC_ERROR_CONTEXT_OVERFLOW = 'datadog.tracer.error.context_overflow'
            METRIC_ERROR_INSTRUMENTATION_PATCH = 'datadog.tracer.error.instrumentation_patch'
            METRIC_ERROR_SPAN_FINISH = 'datadog.tracer.error.span_finish'
            METRIC_ERROR_UNFINISHED_SPANS = 'datadog.tracer.error.unfinished_spans'
            METRIC_INSTRUMENTATION_PATCHED = 'datadog.tracer.instrumentation_patched'
            METRIC_QUEUE_ACCEPTED = 'datadog.tracer.queue.accepted'
            METRIC_QUEUE_ACCEPTED_LENGTHS = 'datadog.tracer.queue.accepted_lengths'
            METRIC_QUEUE_DROPPED = 'datadog.tracer.queue.dropped'
            METRIC_QUEUE_LENGTH = 'datadog.tracer.queue.length'
            METRIC_QUEUE_MAX_LENGTH = 'datadog.tracer.queue.max_length'
            METRIC_QUEUE_SPANS = 'datadog.tracer.queue.spans'
            METRIC_SAMPLING_SERVICE_CACHE_LENGTH = 'datadog.tracer.sampling.service_cache_length'
            METRIC_TRACES_FILTERED = 'datadog.tracer.traces.filtered'
            METRIC_TRANSPORT_CHUNKED = 'datadog.tracer.transport.chunked'
            METRIC_TRANSPORT_TRACE_TOO_LARGE = 'datadog.tracer.transport.trace_too_large'
            METRIC_WRITER_CPU_TIME = 'datadog.tracer.writer.cpu_time'
          end
        end
      end
    end
  end
end
