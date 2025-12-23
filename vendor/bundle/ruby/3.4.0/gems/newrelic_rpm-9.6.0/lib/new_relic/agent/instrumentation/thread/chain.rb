# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic::Agent::Instrumentation
  module MonitoredThread
    module Chain
      def self.instrument!
        ::Thread.class_eval do
          include NewRelic::Agent::Instrumentation::MonitoredThread

          alias_method(:initialize_without_new_relic, :initialize)

          def initialize(*args, &block)
            traced_block = add_thread_tracing(&block)
            initialize_with_newrelic_tracing { initialize_without_new_relic(*args, &traced_block) }
          end
        end
      end
    end
  end
end
