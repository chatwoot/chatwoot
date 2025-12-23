# frozen_string_literal: true

require_relative 'base'

module Datadog
  module Core
    module Telemetry
      module Event
        # Telemetry class for the 'app-integrations-change' event
        class AppIntegrationsChange < Base
          def type
            'app-integrations-change'
          end

          def payload
            {integrations: integrations}
          end

          private

          def integrations
            instrumented_integrations = Datadog.configuration.tracing.instrumented_integrations
            Datadog.registry.map do |integration|
              is_instrumented = instrumented_integrations.include?(integration.name)

              is_enabled = is_instrumented && integration.klass.patcher.patch_successful

              version = integration.klass.class.version&.to_s

              res = {
                name: integration.name.to_s,
                enabled: is_enabled,
                version: version,
                compatible: integration.klass.class.compatible?,
                error: (patch_error(integration) if is_instrumented && !is_enabled),
                # TODO: Track if integration is instrumented by manual configuration or by auto instrumentation
                # auto_enabled: is_enabled && ???,
              }
              res.reject! { |_, v| v.nil? }
              res
            end
          end

          def patch_error(integration)
            patch_error_result = integration.klass.patcher.patch_error_result
            return patch_error_result.compact.to_s if patch_error_result

            # If no error occurred during patching, but integration is still not instrumented
            "Available?: #{integration.klass.class.available?}" \
            ", Loaded? #{integration.klass.class.loaded?}" \
            ", Compatible? #{integration.klass.class.compatible?}" \
            ", Patchable? #{integration.klass.class.patchable?}"
          end
        end
      end
    end
  end
end
