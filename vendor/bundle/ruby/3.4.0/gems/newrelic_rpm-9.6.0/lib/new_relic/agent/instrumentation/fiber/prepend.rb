# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic::Agent::Instrumentation
  module MonitoredFiber
    module Prepend
      include NewRelic::Agent::Instrumentation::MonitoredFiber

      if RUBY_VERSION < '2.7.0'
        def initialize(*_args, &block)
          traced_block = add_thread_tracing(&block)
          initialize_with_newrelic_tracing { super(&traced_block) }
        end
      else
        def initialize(**kawrgs, &block)
          traced_block = add_thread_tracing(&block)
          initialize_with_newrelic_tracing { super(**kawrgs, &traced_block) }
        end
      end
    end
  end
end
