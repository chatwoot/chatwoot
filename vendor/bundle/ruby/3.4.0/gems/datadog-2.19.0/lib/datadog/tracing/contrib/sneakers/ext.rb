# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Sneakers
        # Sneakers integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_SNEAKERS_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_SNEAKERS_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_SNEAKERS_ANALYTICS_SAMPLE_RATE'
          SERVICE_NAME = 'sneakers'
          SPAN_JOB = 'sneakers.job'
          TAG_JOB_ROUTING_KEY = 'sneakers.routing_key'
          TAG_JOB_QUEUE = 'sneakers.queue'
          TAG_JOB_BODY = 'sneakers.body'
          TAG_COMPONENT = 'sneakers'
          TAG_OPERATION_JOB = 'job'
          TAG_MESSAGING_SYSTEM = 'rabbitmq'
          TAG_RABBITMQ_ROUTING_KEY = 'messaging.rabbitmq.routing_key'
        end
      end
    end
  end
end
