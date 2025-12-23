# frozen_string_literal: true

module Sentry
  module Metrics
    class GaugeMetric < Metric
      attr_reader :last, :min, :max, :sum, :count

      def initialize(value)
        value = value.to_f
        @last = value
        @min = value
        @max = value
        @sum = value
        @count = 1
      end

      def add(value)
        value = value.to_f
        @last = value
        @min = [@min, value].min
        @max = [@max, value].max
        @sum += value
        @count += 1
      end

      def serialize
        [last, min, max, sum, count]
      end

      def weight
        5
      end
    end
  end
end
