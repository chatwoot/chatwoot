# frozen_string_literal: true

require_relative '../../ext'
require_relative '../../event'

module Datadog
  module Tracing
    module Contrib
      module Kafka
        module Events
          module Producer
            # Defines instrumentation for deliver_messages.producer.kafka event
            module DeliverMessages
              include Kafka::Event

              EVENT_NAME = 'deliver_messages.producer.kafka'

              module_function

              def on_start(span, _event, _id, payload)
                super

                span.set_tag(Ext::TAG_ATTEMPTS, payload[:attempts]) if payload.key?(:attempts)
                span.set_tag(Ext::TAG_MESSAGE_COUNT, payload[:message_count]) if payload.key?(:message_count)
                if payload.key?(:delivered_message_count)
                  span.set_tag(Ext::TAG_DELIVERED_MESSAGE_COUNT, payload[:delivered_message_count])
                end
                span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_PRODUCER)
              end

              def span_name
                Ext::SPAN_DELIVER_MESSAGES
              end

              def span_options
                super.merge({ tags: { Tracing::Metadata::Ext::TAG_OPERATION => Ext::TAG_OPERATION_DELIVER_MESSAGES } })
              end
            end
          end
        end
      end
    end
  end
end
