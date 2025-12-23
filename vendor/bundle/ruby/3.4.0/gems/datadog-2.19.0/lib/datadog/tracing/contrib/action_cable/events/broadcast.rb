# frozen_string_literal: true

require_relative '../../../metadata/ext'
require_relative '../event'
require_relative '../ext'
require_relative '../../analytics'

module Datadog
  module Tracing
    module Contrib
      module ActionCable
        module Events
          # Defines instrumentation for 'broadcast.action_cable' event.
          #
          # A single 'broadcast' event will trigger as many 'transmit' events
          # as there are clients subscribed to a channel.
          module Broadcast
            include ActionCable::Event

            EVENT_NAME = 'broadcast.action_cable'

            module_function

            def event_name
              self::EVENT_NAME
            end

            def span_name
              Ext::SPAN_BROADCAST
            end

            def span_type
              # Starts a broadcast of messages over WebSockets
              Tracing::Metadata::Ext::AppTypes::TYPE_WEB
            end

            def on_start(span, _event, _id, payload)
              channel = payload[:broadcasting] # Channel has high cardinality
              span.service = configuration[:service_name] if configuration[:service_name]
              span.type = span_type

              # Set analytics sample rate
              if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
                Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
              end

              span.set_tag(Ext::TAG_CHANNEL, channel)
              span.set_tag(Ext::TAG_BROADCAST_CODER, payload[:coder])

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_BROADCAST)
            end
          end
        end
      end
    end
  end
end
