# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation::Sidekiq
  class Server
    include NewRelic::Agent::Instrumentation::ControllerInstrumentation
    include Sidekiq::ServerMiddleware if defined?(Sidekiq::ServerMiddleware)

    ATTRIBUTE_BASE_NAMESPACE = 'sidekiq.args'
    ATTRIBUTE_FILTER_TYPES = %i[include exclude].freeze
    ATTRIBUTE_JOB_NAMESPACE = :"job.#{ATTRIBUTE_BASE_NAMESPACE}"
    INSTRUMENTATION_NAME = 'SidekiqServer'

    # Client middleware has additional parameters, and our tests use the
    # middleware client-side to work inline.
    def call(worker, msg, queue, *_)
      NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

      trace_args = if worker.respond_to?(:newrelic_trace_args)
        worker.newrelic_trace_args(msg, queue)
      else
        self.class.default_trace_args(msg)
      end
      trace_headers = msg.delete(NewRelic::NEWRELIC_KEY)

      perform_action_with_newrelic_trace(trace_args) do
        NewRelic::Agent::Transaction.merge_untrusted_agent_attributes(
          NewRelic::Agent::AttributePreFiltering.pre_filter(msg['args'], self.class.nr_attribute_options),
          ATTRIBUTE_JOB_NAMESPACE,
          NewRelic::Agent::AttributeFilter::DST_NONE
        )

        if ::NewRelic::Agent.config[:'distributed_tracing.enabled'] && trace_headers&.any?
          ::NewRelic::Agent::DistributedTracing::accept_distributed_trace_headers(trace_headers, 'Other')
        end

        yield
      end
    end

    def self.default_trace_args(msg)
      {
        :name => 'perform',
        :class_name => msg['class'],
        :category => 'OtherTransaction/SidekiqJob'
      }
    end

    def self.nr_attribute_options
      @nr_attribute_options ||= begin
        ATTRIBUTE_FILTER_TYPES.each_with_object({}) do |type, opts|
          pattern =
            NewRelic::Agent::AttributePreFiltering.formulate_regexp_union(:"#{ATTRIBUTE_BASE_NAMESPACE}.#{type}")
          opts[type] = pattern if pattern
        end.merge(attribute_namespace: ATTRIBUTE_JOB_NAMESPACE)
      end
    end
  end
end
