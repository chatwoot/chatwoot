# frozen_string_literal: true

require_relative '../analytics'
require_relative '../active_support/notifications/event'
require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      module ActionMailer
        # Defines basic behaviors for an ActionMailer event.
        module Event
          def self.included(base)
            base.send(:include, ActiveSupport::Notifications::Event)
            base.send(:extend, ClassMethods)
          end

          # Class methods for ActionMailer events.
          module ClassMethods
            def span_options
              options = {}
              options[:service] = configuration[:service_name] if configuration[:service_name]
              options
            end

            def configuration
              Datadog.configuration.tracing[:action_mailer]
            end

            def on_start(span, event, _id, payload)
              super

              span.type = span_type
              span.service = configuration[:service_name] if configuration[:service_name]
              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)

              # Set analytics sample rate
              if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
                Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
              end

              # Measure service stats
              Contrib::Analytics.set_measured(span)
            end
          end
        end
      end
    end
  end
end
