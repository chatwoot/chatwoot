# frozen_string_literal: true

require_relative 'configurable'
require_relative 'patchable'
require_relative 'registerable'

module Datadog
  module Tracing
    module Contrib
      # {Integration} provides the basic contract of a tracing integration.
      #
      # An example for a simple instrumentation of a fictional `BillingApi::Client`:
      #
      # ```
      # require 'datadog'
      #
      # module BillingApi
      #   class Integration
      #     include ::Datadog::Tracing::Contrib::Integration
      #
      #     register_as :billing_api # Register in the global tracing registry
      #
      #     def self.available?
      #       defined?(::BillingApi::Client) # Check if the target for instrumentation is present.
      #     end
      #
      #     def new_configuration
      #       Settings.new
      #     end
      #
      #     def patcher
      #       Patcher
      #     end
      #   end
      #
      #   class Settings < ::Datadog::Tracing::Contrib::Configuration::Settings
      #     # Custom service name, if a separate service is desirable for BillingApi calls.
      #     option :service, default: nil
      #   end
      #
      #   module Patcher
      #     include ::Datadog::Tracing::Contrib::Patcher
      #
      #     def self.patch
      #       ::BillingApi::Client.prepend(Instrumentation)
      #     end
      #   end
      #
      #   module Instrumentation
      #     def api_request!(env)
      #       Tracing.trace('billing.request',
      #                            type: 'http',
      #                            service: Datadog.configuration.tracing[:billing_api][:service]) do |span|
      #         span.resource = env[:route].to_s
      #         span.set_tag('client_id', env[:client][:id])
      #
      #         super
      #       end
      #     end
      #   end
      # end
      #
      # Datadog.configure do |c|
      #   c.tracing.instrument :billing_api # Settings (e.g. `service:`) can be provided as keyword arguments.
      # end
      # ```
      #
      # @public_api
      module Integration
        def self.included(base)
          base.include(Configurable)
          base.include(Patchable)
          base.include(Registerable)
        end
      end
    end
  end
end
