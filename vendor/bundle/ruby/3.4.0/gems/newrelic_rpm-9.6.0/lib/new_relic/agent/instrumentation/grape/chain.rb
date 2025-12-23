# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Grape
    module Chain
      def self.instrument!
        Grape::Instrumentation.instrumented_class.class_eval do
          def call_with_new_relic(env)
            begin
              call_without_new_relic(env)
            ensure
              Grape::Instrumentation.capture_transaction(env, self)
            end
          end

          alias_method(:call_without_new_relic, :call)
          alias_method(:call, :call_with_new_relic)
        end
      end
    end
  end
end
