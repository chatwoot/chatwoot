# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Resque
    module Chain
      def self.instrument!
        ::Resque::Job.class_eval do
          include NewRelic::Agent::Instrumentation::Resque

          alias_method(:perform_without_instrumentation, :perform)

          def perform
            with_tracing { perform_without_instrumentation }
          end
        end
      end
    end
  end
end
