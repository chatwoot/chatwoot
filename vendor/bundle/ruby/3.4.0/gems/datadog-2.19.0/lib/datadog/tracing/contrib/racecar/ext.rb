# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Racecar
        # Racecar integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_RACECAR_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_RACECAR_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_RACECAR_ANALYTICS_SAMPLE_RATE'
          DEFAULT_PEER_SERVICE_NAME = 'racecar'
          SPAN_CONSUME = 'racecar.consume'
          SPAN_BATCH = 'racecar.batch'
          SPAN_MESSAGE = 'racecar.message'
          TAG_CONSUMER = 'kafka.consumer'
          TAG_FIRST_OFFSET = 'kafka.first_offset'
          TAG_MESSAGE_COUNT = 'kafka.message_count'
          TAG_OFFSET = 'kafka.offset'
          TAG_PARTITION = 'kafka.partition'
          TAG_TOPIC = 'kafka.topic'
          TAG_COMPONENT = 'racecar'
          TAG_OPERATION_CONSUME = 'consume'
          TAG_OPERATION_BATCH = 'batch'
          TAG_OPERATION_MESSAGE = 'message'
          TAG_MESSAGING_SYSTEM = 'kafka'
        end
      end
    end
  end
end
