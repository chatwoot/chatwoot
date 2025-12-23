# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Bunny::Chain
    def self.instrument!
      ::Bunny::Exchange.class_eval do
        include NewRelic::Agent::Instrumentation::Bunny::Exchange

        alias_method(:publish_without_new_relic, :publish)

        def publish(payload, opts = {})
          publish_with_tracing(payload, opts) { publish_without_new_relic(payload, opts) }
        end
      end

      ::Bunny::Queue.class_eval do
        include NewRelic::Agent::Instrumentation::Bunny::Queue

        alias_method(:pop_without_new_relic, :pop)

        def pop(opts = {:manual_ack => false}, &block)
          pop_with_tracing { pop_without_new_relic(opts, &block) }
        end

        alias_method(:purge_without_new_relic, :purge)

        def purge(*args)
          purge_with_tracing { purge_without_new_relic(*args) }
        end
      end

      ::Bunny::Consumer.class_eval do
        include NewRelic::Agent::Instrumentation::Bunny::Consumer

        alias_method(:call_without_new_relic, :call)

        def call(*args)
          call_with_tracing(*args) { call_without_new_relic(*args) }
        end
      end
    end
  end
end
