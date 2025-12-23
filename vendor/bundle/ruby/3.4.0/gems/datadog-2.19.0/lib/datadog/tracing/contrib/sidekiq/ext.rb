# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Sidekiq
        # Sidekiq integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          CLIENT_SERVICE_NAME = 'sidekiq-client'
          ENV_ENABLED = 'DD_TRACE_SIDEKIQ_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_SIDEKIQ_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_SIDEKIQ_ANALYTICS_SAMPLE_RATE'
          SERVICE_NAME = 'sidekiq'
          SIDEKIQ_8_SECONDS_PER_INTEGER = 0.001 # Sidekiq 8 uses integer epoch milliseconds, rather than epoch floats
          SPAN_PUSH = 'sidekiq.push'
          SPAN_JOB = 'sidekiq.job'
          SPAN_JOB_FETCH = 'sidekiq.job_fetch'
          SPAN_REDIS_INFO = 'sidekiq.redis_info'
          SPAN_HEARTBEAT = 'sidekiq.heartbeat'
          SPAN_SCHEDULED_PUSH = 'sidekiq.scheduled_push'
          SPAN_SCHEDULED_WAIT = 'sidekiq.scheduled_poller_wait'
          SPAN_STOP = 'sidekiq.stop'
          TAG_JOB_DELAY = 'sidekiq.job.delay'
          TAG_JOB_ID = 'sidekiq.job.id'
          TAG_JOB_QUEUE = 'sidekiq.job.queue'
          TAG_JOB_RETRY = 'sidekiq.job.retry'
          TAG_JOB_RETRY_COUNT = 'sidekiq.job.retry_count'
          TAG_JOB_WRAPPER = 'sidekiq.job.wrapper'
          TAG_JOB_ARGS = 'sidekiq.job.args'
          TAG_COMPONENT = 'sidekiq'
          TAG_OPERATION_PUSH = 'push'
          TAG_OPERATION_JOB = 'job'
          TAG_OPERATION_JOB_FETCH = 'job_fetch'
          TAG_OPERATION_REDIS_INFO = 'redis_info'
          TAG_OPERATION_HEARTBEAT = 'heartbeat'
          TAG_OPERATION_SCHEDULED_PUSH = 'scheduled_push'
          TAG_OPERATION_SCHEDULED_WAIT = 'scheduled_poller_wait'
          TAG_OPERATION_STOP = 'stop'
        end
      end
    end
  end
end
