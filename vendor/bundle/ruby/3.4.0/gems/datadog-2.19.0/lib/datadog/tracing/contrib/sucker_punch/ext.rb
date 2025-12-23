# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module SuckerPunch
        # SuckerPunch integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_SUCKER_PUNCH_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_SUCKER_PUNCH_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_SUCKER_PUNCH_ANALYTICS_SAMPLE_RATE'
          SERVICE_NAME = 'sucker_punch'
          SPAN_PERFORM = 'sucker_punch.perform'
          SPAN_PERFORM_ASYNC = 'sucker_punch.perform_async'
          SPAN_PERFORM_IN = 'sucker_punch.perform_in'
          TAG_PERFORM_IN = 'sucker_punch.perform_in'
          TAG_QUEUE = 'sucker_punch.queue'
          TAG_COMPONENT = 'sucker_punch'
          TAG_OPERATION_PERFORM = 'perform'
          TAG_OPERATION_PERFORM_ASYNC = 'perform_async'
          TAG_OPERATION_PERFORM_IN = 'perform_in'
        end
      end
    end
  end
end
