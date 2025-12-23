# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      # Auto-instrumentation for security integrations
      # TODO: this implementation is trivial, check for shareable code with tracer
      module AutoInstrument
        def self.patch_all
          integrations = []

          Datadog::AppSec::Contrib::Integration.registry.each_value do |integration|
            next unless integration.klass.auto_instrument?

            integrations << integration.name
          end

          integrations.each do |integration_name|
            Datadog.configuration.appsec.instrument integration_name
          end
        end
      end
    end
  end
end
