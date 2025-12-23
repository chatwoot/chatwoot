# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic
  module Agent
    module Instrumentation
      module GRPC
        module Server
          module RpcServerPrepend
            include NewRelic::Agent::Instrumentation::GRPC::Server
            def add_http2_port(*args)
              add_http2_port_with_tracing(*args) { super }
            end

            def run(*args)
              run_with_tracing(*args) { super }
            end
          end
        end
      end
    end
  end
end
