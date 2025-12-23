# frozen_string_literal: true

require_relative '../../../metadata/ext'
require_relative '../../analytics'
require_relative '../event'

module Datadog
  module Tracing
    module Contrib
      module ActionCable
        module Events
          # Defines instrumentation for 'perform_action.action_cable' event.
          #
          # An action, triggered by a WebSockets client, invokes a method
          # in the server's channel instance.
          module PerformAction
            include ActionCable::RootContextEvent

            EVENT_NAME = 'perform_action.action_cable'

            module_function

            def event_name
              self::EVENT_NAME
            end

            def span_name
              Ext::SPAN_ACTION
            end

            def span_type
              # A request to perform_action comes from a WebSocket connection
              Tracing::Metadata::Ext::AppTypes::TYPE_WEB
            end

            def on_start(span, _event, _id, payload)
              channel_class = payload[:channel_class]
              action = payload[:action]

              span.service = configuration[:service_name] if configuration[:service_name]
              span.resource = "#{channel_class}##{action}"
              span.type = span_type

              # Set analytics sample rate
              if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
                Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
              end

              # Measure service stats
              Contrib::Analytics.set_measured(span)

              span.set_tag(Ext::TAG_CHANNEL_CLASS, channel_class)
              span.set_tag(Ext::TAG_ACTION, action)

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_ACTION)
            end
          end
        end
      end
    end
  end
end
