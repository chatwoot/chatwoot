# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      # Base provides features that are shared across all integrations
      module Integration
        @registry = {}

        RegisteredIntegration = Struct.new(:name, :klass, :options)

        def self.included(base)
          base.extend(ClassMethods)
        end

        # Class-level methods for Integration
        module ClassMethods
          def register_as(name, options = {})
            Integration.register(self, name, options)
          end

          def compatible?
            true
          end
        end

        def self.register(integration, name, options)
          registry[name] = RegisteredIntegration.new(name, integration, options)
        end

        def self.registry
          @registry
        end
      end
    end
  end
end
