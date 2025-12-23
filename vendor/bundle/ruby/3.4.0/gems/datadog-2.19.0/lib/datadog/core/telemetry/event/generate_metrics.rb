# frozen_string_literal: true

require_relative 'base'

module Datadog
  module Core
    module Telemetry
      module Event
        # Telemetry class for the 'generate-metrics' event
        class GenerateMetrics < Base
          attr_reader :namespace, :metric_series

          def type
            'generate-metrics'
          end

          def initialize(namespace, metric_series)
            super()
            @namespace = namespace
            @metric_series = metric_series
          end

          def payload
            {
              namespace: @namespace,
              series: @metric_series.map(&:to_h)
            }
          end

          def ==(other)
            other.is_a?(GenerateMetrics) && other.namespace == @namespace && other.metric_series == @metric_series
          end

          alias_method :eql?, :==

          def hash
            [self.class, @namespace, @metric_series].hash
          end
        end
      end
    end
  end
end
