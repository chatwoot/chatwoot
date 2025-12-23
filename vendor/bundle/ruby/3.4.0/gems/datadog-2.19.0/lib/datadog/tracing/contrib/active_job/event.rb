# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../active_support/notifications/event'
require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      module ActiveJob
        # Defines basic behaviors for an ActiveJob event.
        module Event
          def self.included(base)
            base.include(ActiveSupport::Notifications::Event)
            base.extend(ClassMethods)
          end

          # Class methods for ActiveJob events.
          module ClassMethods
            def span_options
              options = {}
              options[:service] = configuration[:service_name] if configuration[:service_name]
              options
            end

            def configuration
              Datadog.configuration.tracing[:active_job]
            end

            def set_common_tags(span, payload)
              adapter_name = if payload[:adapter].is_a?(Class)
                               payload[:adapter].name
                             else
                               payload[:adapter].class.name
                             end
              span.set_tag(Ext::TAG_ADAPTER, adapter_name)

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)

              job = payload[:job]
              span.set_tag(Ext::TAG_JOB_ID, job.job_id)
              span.set_tag(Ext::TAG_JOB_QUEUE, job.queue_name)
              span.set_tag(Ext::TAG_JOB_PRIORITY, job.priority) if job.respond_to?(:priority)
              span.set_tag(Ext::TAG_JOB_EXECUTIONS, job.executions) if job.respond_to?(:executions)

              job_scheduled_at = if job.respond_to?(:scheduled_at)
                                   job.scheduled_at
                                 elsif job.respond_to?(:enqueued_at)
                                   job.enqueued_at
                                 end
              span.set_tag(Ext::TAG_JOB_SCHEDULED_AT, Time.at(job_scheduled_at)) if job_scheduled_at
            end
          end
        end
      end
    end
  end
end
