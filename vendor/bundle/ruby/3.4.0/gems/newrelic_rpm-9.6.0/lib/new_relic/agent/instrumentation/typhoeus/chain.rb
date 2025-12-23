# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Typhoeus
    module Chain
      def self.instrument!
        ::Typhoeus::Hydra.class_eval do
          include NewRelic::Agent::Instrumentation::Typhoeus

          def run_with_newrelic(*args)
            with_tracing { run_without_newrelic(*args) }
          end

          alias run_without_newrelic run
          alias run run_with_newrelic
        end
      end
    end
  end
end
