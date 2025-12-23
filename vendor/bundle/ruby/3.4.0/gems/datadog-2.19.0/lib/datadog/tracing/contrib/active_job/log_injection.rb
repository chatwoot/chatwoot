# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module ActiveJob
        # Active Job log injection wrapped around job execution
        module LogInjection
          def self.included(base)
            base.class_eval do
              around_perform do |_, block|
                if Datadog.configuration.tracing.log_injection && logger.respond_to?(:tagged)
                  logger.tagged(Tracing.log_correlation, &block)
                else
                  block.call
                end
              end
            end
          end
        end
      end
    end
  end
end
