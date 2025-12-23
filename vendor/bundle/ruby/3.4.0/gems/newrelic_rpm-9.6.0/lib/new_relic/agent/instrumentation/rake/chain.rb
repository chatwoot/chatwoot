# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Rake
    module Chain
      def self.instrument!
        ::Rake::Task.class_eval do
          include NewRelic::Agent::Instrumentation::Rake::Tracer
          alias_method(:invoke_without_newrelic, :invoke)

          def invoke(*args)
            invoke_with_newrelic_tracing(*args) { invoke_without_newrelic(*args) }
          end
        end
      end
    end
  end
end
