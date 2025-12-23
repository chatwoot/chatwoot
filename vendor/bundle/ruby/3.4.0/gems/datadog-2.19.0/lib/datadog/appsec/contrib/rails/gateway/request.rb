# frozen_string_literal: true

require_relative '../../../instrumentation/gateway/argument'

module Datadog
  module AppSec
    module Contrib
      module Rails
        module Gateway
          # Gateway Request argument. Normalized extration of data from ActionDispatch::Request
          class Request < Instrumentation::Gateway::Argument
            attr_reader :request

            def initialize(request)
              super()
              @request = request
            end

            def env
              request.env
            end

            def headers
              request.headers
            end

            def host
              request.host
            end

            def user_agent
              request.user_agent
            end

            def remote_addr
              request.remote_addr
            end

            def parsed_body
              # force body parameter parsing, which is done lazily by Rails
              request.parameters

              # usually Hash<String,String> but can be a more complex
              # Hash<String,String||Array||Hash> when e.g coming from JSON or
              # with Rails advanced param square bracket parsing
              body = request.env['action_dispatch.request.request_parameters']

              return if body.nil?

              body.reject do |k, _v|
                request.env['action_dispatch.request.path_parameters'].key?(k)
              end
            end

            def route_params
              excluded = [:controller, :action]

              request.env['action_dispatch.request.path_parameters'].reject do |k, _v|
                excluded.include?(k)
              end
            end
          end
        end
      end
    end
  end
end
