# frozen_string_literal: true

require 'json'

require_relative '../negotiation'
require_relative 'client'
require_relative '../../../transport/http/response'
require_relative '../../../transport/http/api/endpoint'

module Datadog
  module Core
    module Remote
      module Transport
        module HTTP
          # HTTP transport behavior for agent feature negotiation
          module Negotiation
            # Response from HTTP transport for agent feature negotiation
            class Response
              include Datadog::Core::Transport::HTTP::Response
              include Core::Remote::Transport::Negotiation::Response

              def initialize(http_response, options = {})
                super(http_response)

                # TODO: transform endpoint hash in a better object for negotiation
                # TODO: transform config in a better object, notably config has max_request_bytes
                @version = options[:version]
                @endpoints = options[:endpoints]
                @config = options[:config]
                @span_events = options[:span_events]
              end
            end

            # Extensions for HTTP client
            module Client
              def send_info_payload(request)
                send_request(request) do |api, env|
                  api.send_info(env)
                end
              end
            end

            module API
              # Extensions for HTTP API Spec
              module Spec
                attr_reader :info

                def info=(endpoint)
                  @info = endpoint
                end

                def send_info(env, &block)
                  raise Core::Transport::HTTP::API::Spec::EndpointNotDefinedError.new('info', self) if info.nil?

                  info.call(env, &block)
                end
              end

              # Extensions for HTTP API Instance
              module Instance
                def send_info(env)
                  unless spec.is_a?(Negotiation::API::Spec)
                    raise Core::Transport::HTTP::API::Instance::EndpointNotSupportedError.new(
                      'info', self
                    )
                  end

                  spec.send_info(env) do |request_env|
                    call(request_env)
                  end
                end
              end

              # Endpoint for negotiation
              class Endpoint < Datadog::Core::Transport::HTTP::API::Endpoint
                def initialize(path)
                  super(:get, path)
                end

                def call(env, &block)
                  # Query for response
                  http_response = super

                  # Process the response
                  body = JSON.parse(http_response.payload, symbolize_names: true) if http_response.ok?

                  # TODO: there should be more processing here to ensure a proper response_options
                  response_options = body.is_a?(Hash) ? body : {}

                  # Build and return a trace response
                  Negotiation::Response.new(http_response, response_options)
                end
              end
            end

            # Add negotiation behavior to transport components
            HTTP::Client.include(Negotiation::Client)
          end
        end
      end
    end
  end
end
