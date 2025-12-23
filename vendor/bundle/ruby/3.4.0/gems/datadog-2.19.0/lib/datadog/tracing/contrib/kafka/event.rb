# frozen_string_literal: true

require_relative '../analytics'
require_relative '../active_support/notifications/event'
require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      module Kafka
        # Defines basic behaviors for an ActiveSupport event.
        module Event
          def self.included(base)
            base.include(ActiveSupport::Notifications::Event)
            base.extend(ClassMethods)
          end

          # Class methods for Kafka events.
          module ClassMethods
            def event_name
              self::EVENT_NAME
            end

            def span_options
              { service: configuration[:service_name] }
            end

            def configuration
              Datadog.configuration.tracing[:kafka]
            end

            def on_start(span, _event, _id, payload)
              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Contrib::Ext::Messaging::TAG_SYSTEM, Ext::TAG_MESSAGING_SYSTEM)

              span.set_tag(Ext::TAG_CLIENT, payload[:client_id])

              # Set analytics sample rate
              if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
                Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
              end

              # Measure service stats
              Contrib::Analytics.set_measured(span)

              report_if_exception(span, payload)
            end
          end
        end
      end
    end
  end
end
