# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Que
        # Que integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_QUE_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_QUE_ANALYTICS_SAMPLE_RATE'
          ENV_ENABLED = 'DD_TRACE_QUE_ENABLED'
          ENV_TAG_ARGS_ENABLED = 'DD_TRACE_QUE_TAG_ARGS_ENABLED'
          ENV_TAG_DATA_ENABLED = 'DD_TRACE_QUE_TAG_DATA_ENABLED'
          SERVICE_NAME = 'que'
          SPAN_JOB = 'que.job'
          TAG_JOB_ARGS = 'que.job.args'
          TAG_JOB_DATA = 'que.job.data'
          TAG_JOB_ERROR_COUNT = 'que.job.error_count'
          TAG_JOB_EXPIRED_AT = 'que.job.expired_at'
          TAG_JOB_FINISHED_AT = 'que.job.finished_at'
          TAG_JOB_ID = 'que.job.id'
          TAG_JOB_PRIORITY = 'que.job.priority'
          TAG_JOB_QUEUE = 'que.job.queue'
          TAG_JOB_RUN_AT = 'que.job.run_at'
          TAG_COMPONENT = 'que'
          TAG_OPERATION_JOB = 'job'
        end
      end
    end
  end
end
