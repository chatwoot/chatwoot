# frozen_string_literal: true

require_relative '../../core/metrics/metric'
require_relative '../../core/diagnostics/health'

module Datadog
  module Tracing
    module Transport
      # Tracks statistics for transports
      module Statistics
        def stats
          @stats ||= Counts.new
        end

        def update_stats_from_response!(response)
          if response.ok?
            stats.success += 1
            stats.consecutive_errors = 0
          else
            stats.client_error += 1 if response.client_error?
            stats.server_error += 1 if response.server_error?
            stats.internal_error += 1 if response.internal_error?
            stats.consecutive_errors += 1
          end

          # Send health metrics
          Datadog.health_metrics.send_metrics(
            metrics_for_response(response).values
          )
        end

        def metrics_for_response(response)
          {}.tap do |metrics|
            metrics[:api_errors] = Core::Metrics::Metric.new(:api_errors, nil, 1) if response.internal_error?
            metrics[:api_responses] = Core::Metrics::Metric.new(:api_responses, nil, 1) unless response.internal_error?
          end
        end

        def update_stats_from_exception!(exception)
          stats.internal_error += 1
          stats.consecutive_errors += 1

          # Send health metrics
          Datadog.health_metrics.send_metrics(
            metrics_for_exception(exception).values
          )
        end

        def metrics_for_exception(_exception)
          { api_errors: Core::Metrics::Metric.new(:api_errors, nil, 1) }
        end

        # Stat counts
        class Counts
          attr_accessor \
            :success,
            :client_error,
            :server_error,
            :internal_error,
            :consecutive_errors

          def initialize
            reset!
          end

          def reset!
            @success = 0
            @client_error = 0
            @server_error = 0
            @internal_error = 0
            @consecutive_errors = 0
          end
        end
      end
    end
  end
end
