# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      # Instrument Rails.
      module Rails
        # Rails log injection helper methods
        module LogInjection
          module_function

          # Use `app.config.log_tags` to inject propagation tags into the default Rails logger.
          def configure_log_tags(app_config)
            # When using SemanticLogger, app_config.log_tags could be a Hash and should not be modified here
            return unless app_config.log_tags.nil? || app_config.log_tags.respond_to?(:<<)

            app_config.log_tags ||= [] # Can be nil, we initialized it if so
            app_config.log_tags << proc { Tracing.log_correlation if Datadog.configuration.tracing.log_injection }
          rescue StandardError => e
            Datadog.logger.warn(
              "Unable to add Datadog Trace context to ActiveSupport::TaggedLogging: #{e.class.name} #{e.message}"
            )
            false
          end
        end
      end
    end
  end
end
