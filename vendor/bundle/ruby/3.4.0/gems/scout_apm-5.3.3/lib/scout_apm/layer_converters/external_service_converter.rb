module ScoutApm
  module LayerConverters
    class ExternalServiceConverter < ConverterBase
      def initialize(*)
        super
        @external_service_metric_set = ExternalServiceMetricSet.new(context)
      end

      def register_hooks(walker)
        super

        return unless scope_layer

        walker.on do |layer|
          next if skip_layer?(layer)
          stat = ExternalServiceMetricStats.new(
            domain_name(layer),
            operation_name(layer),          # operation name/verb. GET/POST/PUT etc.
            scope_layer.legacy_metric_name, # controller_scope
            1,                              # count, this is a single call, so 1
            layer.total_call_time
          )
          @external_service_metric_set << stat
        end
      end

      def record!
        # Everything in the metric set here is from a single transaction, which
        # we want to keep track of. (One web call did a User#find 10 times, but
        # only due to 1 http request)
        @external_service_metric_set.increment_transaction_count!
        @store.track_external_service_metrics!(@external_service_metric_set)

        nil # not returning anything in the layer results ... not used
      end

      def skip_layer?(layer)
        layer.type != 'HTTP' ||
          layer.limited? ||
          super
      end

      private

      # If we can't name the domain name, default to:
      DEFAULT_DOMAIN = "Unknown"

      def domain_name(layer)
        domain = ""
        desc_str = layer.desc.to_s
        desc_str = 'http://' + desc_str unless desc_str =~ /^http/i
        domain = URI.parse(desc_str).host
      rescue
        # Do nothing
      ensure
        domain = DEFAULT_DOMAIN if domain.to_s.blank?
        domain
      end

      def operation_name(layer)
        "all" # Hardcode to "all" until we support breakout by verb
      end
    end
  end
end
