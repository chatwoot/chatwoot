# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      # Initialization hooks for Contrib integrations
      module Component
        class << self
          # Register a callback to be invoked when components are reconfigured.
          # @param name [String] the name of the integration
          # @param callback [Proc] the callback to invoke
          # @yieldparam config [Datadog::Configuration] the configuration to pass to callbacks
          def register(name, &callback)
            @registry[name] = callback
          end

          # Invoke all registered callbacks with the given configuration.
          # @param config [Datadog::Configuration] the configuration to pass to callbacks
          def configure(config)
            @registry.each do |name, callback|
              callback.call(config)
            rescue => e
              Datadog.logger.warn("Error configuring integration #{name}: #{e}")
            end
          end

          private

          # Unregister a callback. This is only used for testing.
          # @param name [String] the name of the integration
          def unregister(name)
            @registry.delete(name)
          end
        end

        # @return [Hash<String, Proc>] the registry of callbacks
        @registry = {}
      end
    end
  end
end
