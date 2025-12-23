# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Rake
    module Prepend
      include NewRelic::Agent::Instrumentation::Rake::Tracer
      def invoke(*args)
        invoke_with_newrelic_tracing(*args) { super }
      end
    end
  end
end
