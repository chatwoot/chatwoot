module ScoutApm
  module Serializers
    class ExternalServiceSerializerToJson
      attr_reader :external_service_metrics

      def initialize(external_service_metrics)
        @external_service_metrics = external_service_metrics
      end

      def as_json
        external_service_metrics.map{|metric| metric.as_json }
      end
    end
  end
end
