# frozen_string_literal: true

module Sentry
  module Metrics
    class LocalAggregator
      # exposed only for testing
      attr_reader :buckets

      def initialize
        @buckets = {}
      end

      def add(key, value)
        if @buckets[key]
          @buckets[key].add(value)
        else
          @buckets[key] = GaugeMetric.new(value)
        end
      end

      def to_hash
        return nil if @buckets.empty?

        @buckets.map do |bucket_key, metric|
          type, key, unit, tags = bucket_key

          payload_key = "#{type}:#{key}@#{unit}"
          payload_value = {
            tags: deserialize_tags(tags),
            min: metric.min,
            max: metric.max,
            count: metric.count,
            sum: metric.sum
          }

          [payload_key, payload_value]
        end.to_h
      end

      private

      def deserialize_tags(tags)
        tags.inject({}) do |h, tag|
          k, v = tag
          old = h[k]
          # make it an array if key repeats
          h[k] = old ? (old.is_a?(Array) ? old << v : [old, v]) : v
          h
        end
      end
    end
  end
end
