# Take a TrackedRequest and turn it into a hash of:
#   MetricMeta => MetricStats

# Full metrics from this request. These get aggregated in Store for the
# overview metrics, or stored permanently in a SlowTransaction
# Some merging of metrics will happen here, so if a request calls the same
# ActiveRecord or View repeatedly, it'll get merged.
module ScoutApm
  module LayerConverters
    class MetricConverter < ConverterBase
      def register_hooks(walker)
        super

        @metrics = {}

        return unless scope_layer

        walker.on do |layer|
          next if skip_layer?(layer)

          meta_options = if layer == scope_layer # We don't scope the controller under itself
                          {}
                        else
                          {:scope => scope_layer.legacy_metric_name}
                        end

          # we don't need to use the full metric name for scoped metrics as we only display metrics aggregrated
          # by type.
          metric_name = meta_options.has_key?(:scope) ? layer.type : layer.legacy_metric_name

          meta = MetricMeta.new(metric_name, meta_options)
          @metrics[meta] ||= MetricStats.new( meta_options.has_key?(:scope) )

          stat = @metrics[meta]
          stat.update!(layer.total_call_time, layer.total_exclusive_time)
        end
      end

      def record!
        @store.track!(@metrics)
        @metrics  # this result must be returned so it can be accessed by transaction callback extensions
      end
    end
  end
end
