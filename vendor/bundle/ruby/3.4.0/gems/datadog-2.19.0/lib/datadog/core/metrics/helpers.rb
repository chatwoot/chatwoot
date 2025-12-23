# frozen_string_literal: true

module Datadog
  module Core
    module Metrics
      # For defining and adding helpers to metrics
      module Helpers
        [
          :count,
          :distribution,
          :increment,
          :gauge,
          :time
        ].each do |metric_type|
          define_method(metric_type) do |name, stat|
            name = name.to_sym
            define_method(name) do |*args, &block|
              send(metric_type, stat, *args, &block)
            end
          end
        end
      end
    end
  end
end
