# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Resque
        # Resque integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_RESQUE_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_RESQUE_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_RESQUE_ANALYTICS_SAMPLE_RATE'
          SERVICE_NAME = 'resque'
          SPAN_JOB = 'resque.job'
          TAG_COMPONENT = 'resque'
          TAG_OPERATION_JOB = 'job'
        end
      end
    end
  end
end
