require 'prometheus/client'

module Weave
  module Core
    class MetricsController < ActionController::API
      def show
        registry = Prometheus::Client.registry
        # Expose process metrics if available (noop by default)
        render plain: Prometheus::Client::Formats::Text.marshal(registry), content_type: 'text/plain; version=0.0.4'
      end
    end
  end
end

