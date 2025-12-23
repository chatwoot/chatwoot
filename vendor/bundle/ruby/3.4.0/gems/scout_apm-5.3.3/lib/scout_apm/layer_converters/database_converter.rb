module ScoutApm
  module LayerConverters
    class DatabaseConverter < ConverterBase
      def initialize(*)
        super
        @db_query_metric_set = DbQueryMetricSet.new(context)
      end

      def register_hooks(walker)
        super

        return unless scope_layer

        walker.on do |layer|
          next if skip_layer?(layer)
          stat = DbQueryMetricStats.new(
            model_name(layer),
            operation_name(layer),
            scope_layer.legacy_metric_name, # controller_scope
            1,                              # count, this is a single query, so 1
            layer.total_call_time,
            records_returned(layer)
          )
          @db_query_metric_set << stat
        end
      end

      def record!
        # Everything in the metric set here is from a single transaction, which
        # we want to keep track of. (One web call did a User#find 10 times, but
        # only due to 1 http request)
        @db_query_metric_set.increment_transaction_count!
        @store.track_db_query_metrics!(@db_query_metric_set)

        nil # not returning anything in the layer results ... not used
      end

      def skip_layer?(layer)
        layer.type != 'ActiveRecord' ||
          layer.limited? ||
          super
      end

      private


      # If we can't name the model, default to:
      DEFAULT_MODEL = "SQL"

      # If we can't name the operation, default to:
      DEFAULT_OPERATION = "other"

      def model_name(layer)
        layer.name.to_s.split("/").first || DEFAULT_MODEL
      end

      def operation_name(layer)
        layer.name.to_s.split("/")[1] || DEFAULT_OPERATION
      end

      def records_returned(layer)
        if layer.annotations
          layer.annotations.fetch(:record_count, 0)
        else
          0
        end
      end
    end
  end
end
