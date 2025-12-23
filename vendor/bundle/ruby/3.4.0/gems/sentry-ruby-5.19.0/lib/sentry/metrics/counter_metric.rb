# frozen_string_literal: true

module Sentry
  module Metrics
    class CounterMetric < Metric
      attr_reader :value

      def initialize(value)
        @value = value.to_f
      end

      def add(value)
        @value += value.to_f
      end

      def serialize
        [value]
      end

      def weight
        1
      end
    end
  end
end
