# frozen_string_literal: true

require_relative 'ext'

module Datadog
  module Tracing
    module Diagnostics
      # Health-related diagnostics
      module Health
        # Health metrics for diagnostics
        module Metrics
          def self.extended(base)
            base.class_eval do
              count :api_errors, Ext::Health::Metrics::METRIC_API_ERRORS
              count :api_requests, Ext::Health::Metrics::METRIC_API_REQUESTS
              count :api_responses, Ext::Health::Metrics::METRIC_API_RESPONSES
              count :error_context_overflow, Ext::Health::Metrics::METRIC_ERROR_CONTEXT_OVERFLOW
              count :error_instrumentation_patch, Ext::Health::Metrics::METRIC_ERROR_INSTRUMENTATION_PATCH
              count :error_span_finish, Ext::Health::Metrics::METRIC_ERROR_SPAN_FINISH
              count :error_unfinished_spans, Ext::Health::Metrics::METRIC_ERROR_UNFINISHED_SPANS
              count :instrumentation_patched, Ext::Health::Metrics::METRIC_INSTRUMENTATION_PATCHED
              count :queue_accepted, Ext::Health::Metrics::METRIC_QUEUE_ACCEPTED
              count :queue_accepted_lengths, Ext::Health::Metrics::METRIC_QUEUE_ACCEPTED_LENGTHS
              count :queue_dropped, Ext::Health::Metrics::METRIC_QUEUE_DROPPED
              count :traces_filtered, Ext::Health::Metrics::METRIC_TRACES_FILTERED
              count :transport_trace_too_large, Ext::Health::Metrics::METRIC_TRANSPORT_TRACE_TOO_LARGE
              count :transport_chunked, Ext::Health::Metrics::METRIC_TRANSPORT_CHUNKED
              count :writer_cpu_time, Ext::Health::Metrics::METRIC_WRITER_CPU_TIME

              gauge :queue_length, Ext::Health::Metrics::METRIC_QUEUE_LENGTH
              gauge :queue_max_length, Ext::Health::Metrics::METRIC_QUEUE_MAX_LENGTH
              gauge :queue_spans, Ext::Health::Metrics::METRIC_QUEUE_SPANS
              gauge :sampling_service_cache_length, Ext::Health::Metrics::METRIC_SAMPLING_SERVICE_CACHE_LENGTH
            end
          end
        end
      end
    end
  end
end
