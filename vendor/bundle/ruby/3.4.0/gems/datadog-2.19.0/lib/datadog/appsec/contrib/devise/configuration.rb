# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module Devise
        # A temporary configuration module to accomodate new RFC changes.
        # NOTE: DEV-3 Remove module
        module Configuration
          TRACK_USER_EVENTS_CONVERSION_RULES = {
            AppSec::Configuration::Settings::SAFE_TRACK_USER_EVENTS_MODE =>
              AppSec::Configuration::Settings::ANONYMIZATION_AUTO_USER_INSTRUMENTATION_MODE,
            AppSec::Configuration::Settings::EXTENDED_TRACK_USER_EVENTS_MODE =>
              AppSec::Configuration::Settings::IDENTIFICATION_AUTO_USER_INSTRUMENTATION_MODE
          }.freeze

          module_function

          # NOTE: DEV-3 Replace method use with `auto_user_instrumentation.enabled?`
          def auto_user_instrumentation_enabled?
            appsec = Datadog.configuration.appsec
            appsec.auto_user_instrumentation.mode

            unless appsec.auto_user_instrumentation.options[:mode].default_precedence?
              return appsec.auto_user_instrumentation.enabled?
            end

            appsec.track_user_events.enabled
          end

          # NOTE: DEV-3 Replace method use with `auto_user_instrumentation.mode`
          def auto_user_instrumentation_mode
            appsec = Datadog.configuration.appsec

            # NOTE: Reading both to trigger precedence set
            appsec.auto_user_instrumentation.mode
            appsec.track_user_events.mode

            if !appsec.track_user_events.options[:mode].default_precedence? &&
                appsec.auto_user_instrumentation.options[:mode].default_precedence?
              return TRACK_USER_EVENTS_CONVERSION_RULES.fetch(
                appsec.track_user_events.mode, appsec.auto_user_instrumentation.mode
              )
            end

            appsec.auto_user_instrumentation.mode
          end
        end
      end
    end
  end
end
