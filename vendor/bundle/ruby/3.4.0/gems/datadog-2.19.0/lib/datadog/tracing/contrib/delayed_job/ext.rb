# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module DelayedJob
        # DelayedJob integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_DELAYED_JOB_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_DELAYED_JOB_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_DELAYED_JOB_ANALYTICS_SAMPLE_RATE'
          SPAN_JOB = 'delayed_job'
          SPAN_ENQUEUE = 'delayed_job.enqueue'
          SPAN_RESERVE_JOB = 'delayed_job.reserve_job'
          TAG_ATTEMPTS = 'delayed_job.attempts'
          TAG_ID = 'delayed_job.id'
          TAG_PRIORITY = 'delayed_job.priority'
          TAG_QUEUE = 'delayed_job.queue'
          TAG_COMPONENT = 'delayed_job'
          TAG_OPERATION_ENQUEUE = 'enqueue'
          TAG_OPERATION_JOB = 'job'
          TAG_OPERATION_RESERVE_JOB = 'reserve_job'
        end
      end
    end
  end
end
