# frozen_string_literal: true

require_relative '../../../transport/http/api/endpoint'
require_relative '../../../transport/http/api/instance'
require_relative '../../../transport/http/api/spec'
require_relative '../../../transport/request'
require_relative 'client'

module Datadog
  module Core
    module Telemetry
      module Transport
        module HTTP
          module Telemetry
            module Client
              def send_telemetry_payload(request)
                send_request(request) do |api, env| # steep:ignore
                  api.send_telemetry(env)
                end
              end
            end

            module API
              class Instance < Core::Transport::HTTP::API::Instance
                def send_telemetry(env)
                  raise Core::Transport::HTTP::API::Instance::EndpointNotSupportedError.new('telemetry', self) unless spec.is_a?(Telemetry::API::Spec)

                  spec.send_telemetry(env) do |request_env|
                    call(request_env)
                  end
                end
              end

              class Spec < Core::Transport::HTTP::API::Spec
                attr_accessor :telemetry

                def send_telemetry(env, &block)
                  raise Core::Transport::HTTP::API::Spec::EndpointNotDefinedError.new('telemetry', self) if telemetry.nil?

                  telemetry.call(env, &block)
                end
              end

              class Endpoint < Datadog::Core::Transport::HTTP::API::Endpoint
                HEADER_CONTENT_TYPE = 'Content-Type'

                attr_reader \
                  :encoder

                def initialize(path, encoder)
                  super(:post, path)
                  @encoder = encoder
                end

                def call(env, &block)
                  # Encode body & type
                  env.headers[HEADER_CONTENT_TYPE] = encoder.content_type
                  env.headers.update(headers(
                    request_type: env.request.request_type,
                    api_key: env.request.api_key,
                  ))
                  env.body = env.request.parcel.data

                  super
                end

                def headers(request_type:, api_key:, api_version: 'v2')
                  {
                    Core::Transport::Ext::HTTP::HEADER_DD_INTERNAL_UNTRACED_REQUEST => '1',
                    # Provided by encoder
                    # 'Content-Type' => 'application/json',
                    'DD-Telemetry-API-Version' => api_version,
                    'DD-Telemetry-Request-Type' => request_type,
                    'DD-Client-Library-Language' => Core::Environment::Ext::LANG,
                    'DD-Client-Library-Version' => Core::Environment::Identity.gem_datadog_version_semver2,

                    # Enable debug mode for telemetry
                    # 'DD-Telemetry-Debug-Enabled' => 'true',
                  }.tap do |result|
                    result['DD-API-KEY'] = api_key unless api_key.nil?
                  end
                end
              end
            end
          end

          HTTP::Client.include(Telemetry::Client)
        end
      end
    end
  end
end
