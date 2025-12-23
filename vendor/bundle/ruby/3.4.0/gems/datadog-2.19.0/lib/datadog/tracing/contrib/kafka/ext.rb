# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Kafka
        # Kafka integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_KAFKA_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_KAFKA_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_KAFKA_ANALYTICS_SAMPLE_RATE'
          SPAN_CONNECTION_REQUEST = 'kafka.connection.request'
          SPAN_CONSUMER_HEARTBEAT = 'kafka.consumer.heartbeat'
          SPAN_CONSUMER_JOIN_GROUP = 'kafka.consumer.join_group'
          SPAN_CONSUMER_LEAVE_GROUP = 'kafka.consumer.leave_group'
          SPAN_CONSUMER_SYNC_GROUP = 'kafka.consumer.sync_group'
          SPAN_DELIVER_MESSAGES = 'kafka.producer.deliver_messages'
          SPAN_PROCESS_BATCH = 'kafka.consumer.process_batch'
          SPAN_PROCESS_MESSAGE = 'kafka.consumer.process_message'
          SPAN_SEND_MESSAGES = 'kafka.producer.send_messages'
          TAG_ATTEMPTS = 'kafka.attempts'
          TAG_API = 'kafka.api'
          TAG_CLIENT = 'kafka.client'
          TAG_GROUP = 'kafka.group'
          TAG_HIGHWATER_MARK_OFFSET = 'kafka.highwater_mark_offset'
          TAG_MESSAGE_COUNT = 'kafka.message_count'
          TAG_MESSAGE_KEY = 'kafka.message_key'
          TAG_DELIVERED_MESSAGE_COUNT = 'kafka.delivered_message_count'
          TAG_OFFSET = 'kafka.offset'
          TAG_OFFSET_LAG = 'kafka.offset_lag'
          TAG_PARTITION = 'kafka.partition'
          TAG_REQUEST_SIZE = 'kafka.request_size'
          TAG_RESPONSE_SIZE = 'kafka.response_size'
          TAG_SENT_MESSAGE_COUNT = 'kafka.sent_message_count'
          TAG_TOPIC = 'kafka.topic'
          TAG_TOPIC_PARTITIONS = 'kafka.topic_partitions'
          TAG_COMPONENT = 'kafka'
          TAG_OPERATION_CONNECTION_REQUEST = 'connection.request'
          TAG_OPERATION_CONSUMER_HEARTBEAT = 'consumer.heartbeat'
          TAG_OPERATION_CONSUMER_JOIN_GROUP = 'consumer.join_group'
          TAG_OPERATION_CONSUMER_LEAVE_GROUP = 'consumer.leave_group'
          TAG_OPERATION_CONSUMER_SYNC_GROUP = 'consumer.sync_group'
          TAG_OPERATION_DELIVER_MESSAGES = 'producer.deliver_messages'
          TAG_OPERATION_PROCESS_BATCH = 'consumer.process_batch'
          TAG_OPERATION_PROCESS_MESSAGE = 'consumer.process_message'
          TAG_OPERATION_SEND_MESSAGES = 'producer.send_messages'
          TAG_MESSAGING_SYSTEM = 'kafka'
          TAG_KAFKA_BOOTSTRAP_SERVERS = 'messaging.kafka.bootstrap.servers'
        end
      end
    end
  end
end
