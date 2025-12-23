# frozen_string_literal: true

require_relative '../analytics'

module Datadog
  module Tracing
    module Contrib
      module ActionPack
        # Common utilities for ActionPack
        module Utils
          def self.exception_is_error?(exception)
            if defined?(::ActionDispatch::ExceptionWrapper)
              # Gets the equivalent status code for the exception (not all are 5XX)
              # You can add custom errors via `config.action_dispatch.rescue_responses`
              status = ::ActionDispatch::ExceptionWrapper.status_code_for_exception(exception.class.name)
              # Only 5XX exceptions are actually errors (e.g. don't flag 404s)
              status.to_s.start_with?('5')
            else
              true
            end
          end

          def self.set_analytics_sample_rate(span)
            if Contrib::Analytics.enabled?(datadog_configuration[:analytics_enabled])
              Contrib::Analytics.set_sample_rate(span, datadog_configuration[:analytics_sample_rate])
            end
          end

          class << self
            private

            def datadog_configuration
              Datadog.configuration.tracing[:action_pack]
            end
          end
        end
      end
    end
  end
end
