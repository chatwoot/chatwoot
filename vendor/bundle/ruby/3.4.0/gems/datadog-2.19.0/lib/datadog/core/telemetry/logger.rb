# frozen_string_literal: true

module Datadog
  module Core
    module Telemetry
      # === INTERNAL USAGE ONLY ===
      #
      # Report telemetry logs via delegating to the telemetry component instance via mutex.
      #
      # IMPORTANT: Invoking this method during the lifecycle of component initialization will
      # be no-op instead.
      #
      # For developer using this module:
      #   read: lib/datadog/core/telemetry/logging.rb
      module Logger
        class << self
          def report(exception, level: :error, description: nil, pii_safe: false)
            instance&.report(exception, level: level, description: description, pii_safe: pii_safe)
          end

          def error(description)
            instance&.error(description)
          end

          private

          def instance
            # Component initialization uses a mutex to avoid having concurrent initialization.
            # Trying to access the telemetry component during initialization (specifically:
            # from the thread that's actually doing the initialization) would cause a deadlock,
            # since accessing the components would try to recursively lock the mutex.
            #
            # To work around this, we use allow_initialization: false to avoid triggering this issue.
            #
            # The downside is: this leaves us unable to report telemetry during component initialization.
            components = Datadog.send(:components, allow_initialization: false)
            telemetry = components&.telemetry

            if telemetry
              telemetry
            else
              Datadog.logger.warn(
                'Failed to send telemetry before components initialization or within components lifecycle'
              )
              nil
            end
          end
        end
      end
    end
  end
end
