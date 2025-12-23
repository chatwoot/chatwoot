# frozen_string_literal: true

require 'sentry/metrics/metric'
require 'sentry/metrics/counter_metric'
require 'sentry/metrics/distribution_metric'
require 'sentry/metrics/gauge_metric'
require 'sentry/metrics/set_metric'
require 'sentry/metrics/timing'
require 'sentry/metrics/aggregator'

module Sentry
  module Metrics
    DURATION_UNITS = %w[nanosecond microsecond millisecond second minute hour day week]
    INFORMATION_UNITS = %w[bit byte kilobyte kibibyte megabyte mebibyte gigabyte gibibyte terabyte tebibyte petabyte pebibyte exabyte exbibyte]
    FRACTIONAL_UNITS = %w[ratio percent]

    OP_NAME = 'metric.timing'
    SPAN_ORIGIN = 'auto.metric.timing'

    class << self
      def increment(key, value = 1.0, unit: 'none', tags: {}, timestamp: nil)
        Sentry.metrics_aggregator&.add(:c, key, value, unit: unit, tags: tags, timestamp: timestamp)
      end

      def distribution(key, value, unit: 'none', tags: {}, timestamp: nil)
        Sentry.metrics_aggregator&.add(:d, key, value, unit: unit, tags: tags, timestamp: timestamp)
      end

      def set(key, value, unit: 'none', tags: {}, timestamp: nil)
        Sentry.metrics_aggregator&.add(:s, key, value, unit: unit, tags: tags, timestamp: timestamp)
      end

      def gauge(key, value, unit: 'none', tags: {}, timestamp: nil)
        Sentry.metrics_aggregator&.add(:g, key, value, unit: unit, tags: tags, timestamp: timestamp)
      end

      def timing(key, unit: 'second', tags: {}, timestamp: nil, &block)
        return unless block_given?
        return yield unless DURATION_UNITS.include?(unit)

        result, value = Sentry.with_child_span(op: OP_NAME, description: key, origin: SPAN_ORIGIN) do |span|
          tags.each { |k, v| span.set_tag(k, v.is_a?(Array) ? v.join(', ') : v.to_s) } if span

          start = Timing.send(unit.to_sym)
          result = yield
          value = Timing.send(unit.to_sym) - start

          [result, value]
        end

        Sentry.metrics_aggregator&.add(:d, key, value, unit: unit, tags: tags, timestamp: timestamp)
        result
      end
    end
  end
end
