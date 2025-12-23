# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module ActiveJob
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_ACTIVE_JOB_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_ACTIVE_JOB_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_ACTIVE_JOB_ANALYTICS_SAMPLE_RATE'

          SPAN_DISCARD = 'active_job.discard'
          SPAN_ENQUEUE = 'active_job.enqueue'
          SPAN_ENQUEUE_RETRY = 'active_job.enqueue_retry'
          SPAN_PERFORM = 'active_job.perform'
          SPAN_RETRY_STOPPED = 'active_job.retry_stopped'

          TAG_COMPONENT = 'active_job'
          TAG_OPERATION_DISCARD = 'discard'
          TAG_OPERATION_ENQUEUE = 'enqueue'
          TAG_OPERATION_ENQUEUE_AT = 'enqueue_at'
          TAG_OPERATION_ENQUEUE_RETRY = 'enqueue_retry'
          TAG_OPERATION_PERFORM = 'perform'
          TAG_OPERATION_RETRY_STOPPED = 'retry_stopped'

          TAG_ADAPTER = 'active_job.adapter'
          TAG_JOB_ERROR = 'active_job.job.error'
          TAG_JOB_EXECUTIONS = 'active_job.job.executions'
          TAG_JOB_ID = 'active_job.job.id'
          TAG_JOB_PRIORITY = 'active_job.job.priority'
          TAG_JOB_QUEUE = 'active_job.job.queue'
          TAG_JOB_RETRY_WAIT = 'active_job.job.retry_wait'
          TAG_JOB_SCHEDULED_AT = 'active_job.job.scheduled_at'
        end
      end
    end
  end
end
