# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module MonitoredFiber::Chain
    def self.instrument!
      ::Fiber.class_eval do
        include NewRelic::Agent::Instrumentation::MonitoredFiber

        alias_method(:initialize_without_new_relic, :initialize)

        if RUBY_VERSION < '2.7.0'
          def initialize(*_args, &block)
            traced_block = add_thread_tracing(&block)
            initialize_with_newrelic_tracing { initialize_without_new_relic(&traced_block) }
          end
        else
          def initialize(**kwargs, &block)
            traced_block = add_thread_tracing(&block)
            initialize_with_newrelic_tracing { initialize_without_new_relic(**kwargs, &traced_block) }
          end
        end
      end
    end
  end
end
