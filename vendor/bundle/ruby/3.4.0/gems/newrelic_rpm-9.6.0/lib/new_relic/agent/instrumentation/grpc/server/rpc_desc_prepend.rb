# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic
  module Agent
    module Instrumentation
      module GRPC
        module Server
          module RpcDescPrepend
            include NewRelic::Agent::Instrumentation::GRPC::Server

            def handle_request_response(active_call, mth, inter_ctx)
              handle_with_tracing(:request_response, active_call, mth, inter_ctx) { super }
            end

            def handle_client_streamer(active_call, mth, inter_ctx)
              handle_with_tracing(:client_streamer, active_call, mth, inter_ctx) { super }
            end

            def handle_server_streamer(active_call, mth, inter_ctx)
              handle_with_tracing(:server_streamer, active_call, mth, inter_ctx) { super }
            end

            def handle_bidi_streamer(active_call, mth, inter_ctx)
              handle_with_tracing(:bidi_streamer, active_call, mth, inter_ctx) { super }
            end
          end
        end
      end
    end
  end
end
