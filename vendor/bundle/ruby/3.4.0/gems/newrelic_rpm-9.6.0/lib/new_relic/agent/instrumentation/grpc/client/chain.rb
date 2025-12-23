# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic::Agent::Instrumentation
  module GRPC
    module Client
      module Chain
        def self.instrument!
          ::GRPC::ClientStub.class_eval do
            include NewRelic::Agent::Instrumentation::GRPC::Client

            def bidi_streamer_with_new_relic_trace(method, requests, marshal, unmarshal,
              deadline: nil,
              return_op: false,
              parent: nil,
              credentials: nil,
              metadata: {},
              &blk)

              issue_request_with_tracing(:bidi_streamer, method, requests, marshal, unmarshal,
                deadline: deadline,
                return_op: return_op,
                parent: parent,
                credentials: credentials,
                metadata: metadata)

              # TODO: gRPC - confirm that &blk is being invoked correctly
            end

            alias bidi_streamer_without_newrelic_trace bidi_streamer
            alias bidi_streamer bidi_streamer_with_newrelic_trace

            def client_streamer_with_newrelic_trace(method, requests, marshal, unmarshal,
              deadline: nil,
              return_op: false,
              parent: nil,
              credentials: nil,
              metadata: {})

              issue_request_with_tracing(:client_streamer, method, requests, marshal, unmarshal,
                deadline: deadline,
                return_op: return_op,
                parent: parent,
                credentials: credentials,
                metadata: metadata)
            end

            alias client_streamer_without_newrelic_trace client_streamer
            alias client_streamer client_streamer_with_newrelic_trace

            def request_response_with_newrelic_trace(method, req, marshal, unmarshal,
              deadline: nil,
              return_op: false,
              parent: nil,
              credentials: nil,
              metadata: {})

              issue_request_with_tracing(:request_response, method, req, marshal, unmarshal,
                deadline: deadline,
                return_op: return_op,
                parent: parent,
                credentials: credentials,
                metadata: metadata)
            end

            alias request_response_without_newrelic_trace request_response
            alias request_response request_response_with_newrelic_trace

            def server_streamer_with_newrelic_trace(method, req, marshal, unmarshal,
              deadline: nil,
              return_op: false,
              parent: nil,
              credentials: nil,
              metadata: {},
              &blk)

              issue_request_with_tracing(:server_streamer, method, req, marshal, unmarshal,
                deadline: deadline,
                return_op: return_op,
                parent: parent,
                credentials: credentials,
                metadata: metadata)

              # TODO: gRPC - confirm that &blk is being invoked correctly
            end

            alias server_streamer_without_newrelic_trace server_streamer
            alias server_streamer server_streamer_with_newrelic_trace
          end
        end
      end
    end
  end
end
