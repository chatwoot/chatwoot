# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation::Sidekiq
  class Client
    include Sidekiq::ClientMiddleware if defined?(Sidekiq::ClientMiddleware)

    INSTRUMENTATION_NAME = 'SidekiqClient'

    def call(_worker_class, job, *_)
      NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

      job[NewRelic::NEWRELIC_KEY] ||= distributed_tracing_headers if ::NewRelic::Agent.config[:'distributed_tracing.enabled']
      yield
    end

    def distributed_tracing_headers
      headers = {}
      ::NewRelic::Agent::DistributedTracing.insert_distributed_trace_headers(headers)
      headers
    end
  end
end
