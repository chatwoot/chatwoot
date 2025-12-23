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
          # Defines instrumentation for 'transmit.action_cable' event.
          #
          # A 'transmit' event sends a message to a single client subscribed to a channel.
          module Transmit
            include ActionCable::Event

            EVENT_NAME = 'transmit.action_cable'

            module_function

            def event_name
              self::EVENT_NAME
            end

            def span_name
              Ext::SPAN_TRANSMIT
            end

            def span_type
              # ActionCable transmits data over WebSockets
              Tracing::Metadata::Ext::AppTypes::TYPE_WEB
            end

            def on_start(span, _event, _id, payload)
              channel_class = payload[:channel_class]

              span.service = configuration[:service_name] if configuration[:service_name]
              span.resource = channel_class
              span.type = span_type

              # Set analytics sample rate
              if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
                Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
              end

              span.set_tag(Ext::TAG_CHANNEL_CLASS, channel_class)
              span.set_tag(Ext::TAG_TRANSMIT_VIA, payload[:via])

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_TRANSMIT)
            end
          end
        end
      end
    end
  end
end
