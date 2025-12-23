# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic
  module Agent
    module Instrumentation
      module NetHTTP
        module Prepend
          include NewRelic::Agent::Instrumentation::NetHTTP

          def request(request, *args, &block)
            request_with_tracing(request) { super }
          end
        end
      end
    end
  end
end
