# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic
  module Agent
    module Instrumentation
      module Curb
        module Easy
          module Prepend
            include NewRelic::Agent::Instrumentation::Curb::Easy

            def http_head(*args, &blk)
              http_head_with_tracing { super }
            end

            def http_post(*args, &blk)
              http_post_with_tracing { super }
            end

            def http_put(*args, &blk)
              http_put_with_tracing { super }
            end

            def http(verb)
              http_with_tracing(verb) { super }
            end

            def perform
              perform_with_tracing { super }
            end

            def method(verb)
              method_with_tracing(verb) { super }
            end

            def header_str
              header_str_with_tracing { super }
            end
          end
        end

        module Multi
          module Prepend
            include NewRelic::Agent::Instrumentation::Curb::Multi

            def add(curl)
              add_with_tracing(curl) { super }
            end

            def perform(&blk)
              perform_with_tracing { super }
            end
          end
        end
      end
    end
  end
end
