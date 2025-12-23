# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/sampler'
require 'new_relic/delayed_job_injection'

module NewRelic
  module Agent
    module Samplers
      # This sampler records the status of your delayed job table once a minute.
      # It assumes jobs are cleared after being run, and failed jobs are not (otherwise
      # the failed job metric is useless).
      #
      # In earlier versions it will break out the queue length by priority.  In later
      # versions of DJ where distinct queues are supported, it breaks it out by queue name.
      #
      class DelayedJobSampler < NewRelic::Agent::Sampler
        named :delayed_job

        # DelayedJob supports multiple backends, only some of which we can
        # handle. Check whether we think we've got what we need here.
        def self.supported_backend?
          ::Delayed::Worker.backend.to_s == 'Delayed::Backend::ActiveRecord::Job'
        end

        def initialize
          raise Unsupported, 'DJ queue sampler disabled' if Agent.config[:'instrumentation.delayed_job'] == 'disabled'
          raise Unsupported, "DJ queue sampling unsupported with backend '#{::Delayed::Worker.backend}'" unless self.class.supported_backend?
          raise Unsupported, 'No DJ worker present. Skipping DJ queue sampler' unless NewRelic::DelayedJobInjection.worker_name
        end

        def record_failed_jobs(value)
          NewRelic::Agent.record_metric('Workers/DelayedJob/failed_jobs', value)
        end

        def record_locked_jobs(value)
          NewRelic::Agent.record_metric('Workers/DelayedJob/locked_jobs', value)
        end

        FAILED_QUERY = 'failed_at is not NULL'.freeze
        LOCKED_QUERY = 'locked_by is not NULL'.freeze

        def failed_jobs
          count(FAILED_QUERY)
        end

        def locked_jobs
          count(LOCKED_QUERY)
        end

        def count(query)
          if ::ActiveRecord::VERSION::MAJOR.to_i < 4
            ::Delayed::Job.count(:conditions => query)
          else
            ::Delayed::Job.where(query).count
          end
        end

        def self.supported_on_this_platform?
          defined?(::Delayed::Job)
        end

        def poll
          # Wrapping these queries within the same connection avoids deadlocks
          ActiveRecord::Base.connection_pool.with_connection do
            record_failed_jobs(failed_jobs)
            record_locked_jobs(locked_jobs)
            record_queue_length_metrics
          end
        end

        private

        def record_queue_length_metrics
          counts = []
          counts << record_counts_by('queue', 'name') if ::Delayed::Job.instance_methods.include?(:queue)
          counts << record_counts_by('priority')

          all_metric = 'Workers/DelayedJob/queue_length/all'
          NewRelic::Agent.record_metric(all_metric, counts.max)
        end

        QUEUE_QUERY_CONDITION = 'run_at <= ? and failed_at is NULL'.freeze

        def record_counts_by(column_name, metric_node = column_name)
          all_count = 0
          queue_counts(column_name).each do |column_val, count|
            all_count += count
            column_val = 'default' if column_val.nil? || column_val == NewRelic::EMPTY_STR
            metric = "Workers/DelayedJob/queue_length/#{metric_node}/#{column_val}"
            NewRelic::Agent.record_metric(metric, count)
          end
          all_count
        end

        def queue_counts(column_name)
          now = ::Delayed::Job.db_time_now
          # There is not an ActiveRecord syntax for what we're trying to do
          # here that's valid on 2.x through 4.1, so split it up.
          result = if ::ActiveRecord::VERSION::MAJOR.to_i < 4
            ::Delayed::Job.count(:group => column_name,
              :conditions => [QUEUE_QUERY_CONDITION, now])
          else
            ::Delayed::Job.where(QUEUE_QUERY_CONDITION, now)
              .group(column_name)
              .count
          end
          result.to_a
        end
      end
    end
  end
end
