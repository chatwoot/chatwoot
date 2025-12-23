# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Ethon
    module Easy
      module Prepend
        include NewRelic::Agent::Instrumentation::Ethon::Easy

        def fabricate(url, action_name, options)
          fabricate_with_tracing(url, action_name, options) { super }
        end

        def headers=(headers)
          headers_equals_with_tracing(headers) { super }
        end

        def perform(*args)
          perform_with_tracing(*args) { super }
        end
      end
    end

    module Multi
      module Prepend
        include NewRelic::Agent::Instrumentation::Ethon::Multi

        def perform(*args)
          perform_with_tracing(*args) { super }
        end
      end
    end
  end
end
