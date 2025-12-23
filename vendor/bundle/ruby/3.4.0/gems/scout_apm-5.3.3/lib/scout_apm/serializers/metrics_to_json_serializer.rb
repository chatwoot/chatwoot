module ScoutApm
  module Serializers
    class MetricsToJsonSerializer
      attr_reader :metrics

      # A hash of meta => stat pairs
      def initialize(metrics)
        @metrics = metrics
      end

      def as_json
        if metrics
          metrics.map{|meta, stat| metric_as_json(meta, stat) }
        else
          nil
        end
      end

      # Children metrics is a hash of meta=>stat pairs. Leave empty for no children.
      # Supports only a single-level nesting, until we have redone metric
      # classes, instead of Meta and Stats
      def metric_as_json(meta, stat, child_metrics={})
        { "bucket" => meta.type,
          "name" => meta.name, # No scope values needed here, since it's implied by the nesting.

          "count" => stat.call_count,
          "total_call_time" => stat.total_call_time,
          "total_exclusive_time" => stat.total_exclusive_time,
          "min_call_time" => stat.min_call_time,
          "max_call_time" => stat.max_call_time,

          # Pretty unsure how to synthesize histograms out of what we store now
          "total_histogram" => [
            [stat.total_exclusive_time / stat.call_count, stat.call_count],
          ],
          "exclusive_histogram" => [
            [stat.total_exclusive_time / stat.call_count, stat.call_count]
          ],

          "metrics" => transform_child_metrics(child_metrics),

          # Will later hold the exact SQL, or URL or whatever other detail
          # about this query is necessary
          "detail" => { :desc => meta.desc }.merge(meta.extra || {}),
        }
      end

      def transform_child_metrics(metrics)
        metrics.map do |meta, stat|
          metric_as_json(meta, stat)
        end
      end
    end
  end
end


