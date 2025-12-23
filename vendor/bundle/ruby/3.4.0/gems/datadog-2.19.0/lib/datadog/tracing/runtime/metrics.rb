# frozen_string_literal: true

module Datadog
  module Tracing
    module Runtime
      # Decorates runtime metrics feature
      module Metrics
        def self.associate_trace(trace)
          return unless trace && !trace.empty?

          # Register service as associated with metrics
          Datadog.send(:components).runtime_metrics.register_service(trace.service) unless trace.service.nil?
        end
      end
    end
  end
end
