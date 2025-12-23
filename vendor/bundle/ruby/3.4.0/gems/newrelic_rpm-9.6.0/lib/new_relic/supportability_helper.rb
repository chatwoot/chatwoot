# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module SupportabilityHelper
    API_SUPPORTABILITY_PREFIX = 'Supportability/API/'.freeze

    # pre-instantiate these strings as they may be used multiple times per
    # transaction, just to eke out a bit less performance hit
    #
    API_SUPPORTABILITY_METRICS = [
      :insert_distributed_trace_headers,
      :accept_distributed_trace_headers,
      :add_custom_attributes,
      :add_custom_log_attributes,
      :add_custom_span_attributes,
      :add_instrumentation,
      :add_method_tracer,
      :add_transaction_tracer,
      :after_fork,
      :browser_timing_header,
      :disable_all_tracing,
      :disable_sql_recording,
      :drop_buffered_data,
      :get_request_metadata,
      :get_response_metadata,
      :get_transaction_name,
      :ignore_apdex,
      :ignore_enduser,
      :ignore_error_filter,
      :ignore_transaction,
      :increment_metric,
      :manual_start,
      :newrelic_ignore,
      :newrelic_ignore_apdex,
      :newrelic_ignore_enduser,
      :notice_error,
      :notice_sql,
      :notice_statement,
      :perform_action_with_newrelic_trace,
      :process_request_metadata,
      :process_response_metadata,
      :record_custom_event,
      :record_metric,
      :recording_web_transaction?,
      :require_test_helper,
      :set_error_group_callback,
      :set_segment_callback,
      :set_sql_obfuscator,
      :set_transaction_name,
      :set_user_id,
      :shutdown,
      :start_segment,
      :trace,
      :traced_thread,
      :trace_execution_scoped,
      :trace_execution_unscoped,
      :wrap
    ].reduce({}) do |h, o|
      h[o] = API_SUPPORTABILITY_PREFIX + o.to_s
      h
    end

    def record_api_supportability_metric(method_name)
      agent = NewRelic::Agent.agent or return
      if metric = API_SUPPORTABILITY_METRICS[method_name]
        agent.stats_engine.tl_record_unscoped_metrics(metric, &:increment_count)
      else
        NewRelic::Agent.logger.debug("API supportability metric not found for :#{method_name}")
      end
    end

    def valid_api_argument_class?(arg, name, klass)
      return true if arg.is_a?(klass)

      caller_location = caller_locations(1..1).first.label

      message = "Bad argument passed to ##{caller_location}. " \
        "Expected #{klass} for `#{name}` but got #{arg.class}"

      NewRelic::Agent.logger.warn(message)
      nil
    end
  end
end
