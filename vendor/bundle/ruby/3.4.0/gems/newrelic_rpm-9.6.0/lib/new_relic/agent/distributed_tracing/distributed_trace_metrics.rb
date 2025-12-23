# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module DistributedTraceMetrics
      extend self

      ALL_SUFFIX = 'all'
      ALL_WEB_SUFFIX = 'allWeb'
      ALL_OTHER_SUFFIX = 'allOther'

      UNKNOWN_CALLER_PREFIX = '%s/Unknown/Unknown/Unknown/%s'

      def transaction_type_suffix
        if Transaction.recording_web_transaction?
          ALL_WEB_SUFFIX
        else
          ALL_OTHER_SUFFIX
        end
      end

      def record_metrics_for_transaction(transaction)
        return unless Agent.config[:'distributed_tracing.enabled']

        dt = transaction.distributed_tracer
        payload = dt.distributed_trace_payload || dt.trace_state_payload

        record_caller_by_duration_metrics(transaction, payload)
        record_transport_duration_metrics(transaction, payload)
        record_errors_by_caller_metrics(transaction, payload)
      end

      def prefix_for_metric(name, transaction, payload)
        if payload
          "#{name}/" \
          "#{payload.parent_type}/" \
          "#{payload.parent_account_id}/" \
          "#{payload.parent_app_id}/" \
          "#{transaction.distributed_tracer.caller_transport_type}"
        else
          UNKNOWN_CALLER_PREFIX % [name, transaction.distributed_tracer.caller_transport_type]
        end
      end

      def record_caller_by_duration_metrics(transaction, payload)
        prefix = prefix_for_metric('DurationByCaller', transaction, payload)
        record_unscoped_metric(transaction, prefix, transaction.duration)
      end

      def record_transport_duration_metrics(transaction, payload)
        return unless payload

        prefix = prefix_for_metric('TransportDuration', transaction, payload)
        duration = transaction.calculate_transport_duration(payload)
        record_unscoped_metric(transaction, prefix, duration)
      end

      def record_errors_by_caller_metrics(transaction, payload)
        return unless transaction.exceptions.size > 0

        prefix = prefix_for_metric('ErrorsByCaller', transaction, payload)
        record_unscoped_metric(transaction, prefix, 1)
      end

      private

      def record_unscoped_metric(transaction, prefix, duration)
        transaction.metrics.record_unscoped("#{prefix}/#{ALL_SUFFIX}", duration)
        transaction.metrics.record_unscoped("#{prefix}/#{transaction_type_suffix}", duration)
      end
    end
  end
end
