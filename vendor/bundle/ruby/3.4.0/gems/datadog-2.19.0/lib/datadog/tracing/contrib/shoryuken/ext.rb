# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Shoryuken
        # Shoryuken integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_SHORYUKEN_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_SHORYUKEN_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_SHORYUKEN_ANALYTICS_SAMPLE_RATE'
          SERVICE_NAME = 'shoryuken'
          SPAN_JOB = 'shoryuken.job'
          TAG_JOB_ID = 'shoryuken.id'
          TAG_JOB_QUEUE = 'shoryuken.queue'
          TAG_JOB_ATTRIBUTES = 'shoryuken.attributes'
          TAG_JOB_BODY = 'shoryuken.body'
          TAG_COMPONENT = 'shoryuken'
          TAG_OPERATION_JOB = 'job'
          TAG_MESSAGING_SYSTEM = 'amazonsqs'
        end
      end
    end
  end
end
