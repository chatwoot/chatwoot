# frozen_string_literal: true

require_relative '../../ext'
require_relative '../../event'
require_relative '../../consumer_event'
require_relative '../../consumer_group_event'

module Datadog
  module Tracing
    module Contrib
      module Kafka
        module Events
          module ConsumerGroup
            # Defines instrumentation for heartbeat.consumer.kafka event
            module Heartbeat
              include Kafka::Event
              extend Kafka::ConsumerEvent
              extend Kafka::ConsumerGroupEvent

              EVENT_NAME = 'heartbeat.consumer.kafka'

              module_function

              def on_start(span, _event, _id, payload)
                super

                if payload.key?(:topic_partitions)
                  payload[:topic_partitions].each do |topic, partitions|
                    span.set_tag("#{Ext::TAG_TOPIC_PARTITIONS}.#{topic}", partitions)
                  end
                end
              end

              def span_name
                Ext::SPAN_CONSUMER_HEARTBEAT
              end

              def span_options
                super.merge({ tags: { Tracing::Metadata::Ext::TAG_OPERATION => Ext::TAG_OPERATION_CONSUMER_HEARTBEAT } })
              end
            end
          end
        end
      end
    end
  end
end
