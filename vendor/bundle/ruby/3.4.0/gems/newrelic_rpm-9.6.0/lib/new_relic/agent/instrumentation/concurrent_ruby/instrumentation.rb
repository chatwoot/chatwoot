# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module ConcurrentRuby
    SEGMENT_NAME = 'Concurrent/Task'
    INSTRUMENTATION_NAME = NewRelic::Agent.base_name(name)

    def add_task_tracing(&task)
      NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

      NewRelic::Agent::Tracer.thread_block_with_current_transaction(
        segment_name: SEGMENT_NAME,
        parent: NewRelic::Agent::Tracer.current_segment,
        &task
      )
    end
  end
end
