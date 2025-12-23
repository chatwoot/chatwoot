# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module MonitoredThread
        attr_reader :nr_parent_key

        def initialize_with_newrelic_tracing
          @nr_parent_key = NewRelic::Agent::Tracer.current_segment_key
          yield
        end

        def add_thread_tracing(*args, &block)
          return block if !NewRelic::Agent::Tracer.thread_tracing_enabled?

          NewRelic::Agent::Tracer.thread_block_with_current_transaction(
            segment_name: 'Ruby/Thread',
            &block
          )
        end
      end
    end
  end
end
