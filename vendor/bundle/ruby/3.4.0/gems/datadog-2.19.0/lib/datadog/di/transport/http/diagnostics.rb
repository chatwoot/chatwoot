# frozen_string_literal: true

require_relative '../../../core/transport/http/api/instance'
require_relative '../../../core/transport/http/api/spec'
require_relative 'client'

module Datadog
  module DI
    module Transport
      module HTTP
        module Diagnostics
          module Client
            def send_diagnostics_payload(request)
              send_request(request) do |api, env|
                api.send_diagnostics(env)
              end
            end
          end

          module API
            class Instance < Core::Transport::HTTP::API::Instance
              def send_diagnostics(env)
                raise Core::Transport::HTTP::API::Instance::EndpointNotSupportedError.new('diagnostics', self) unless spec.is_a?(Diagnostics::API::Spec)

                spec.send_diagnostics(env) do |request_env|
                  call(request_env)
                end
              end
            end

            class Spec < Core::Transport::HTTP::API::Spec
              attr_accessor :diagnostics

              def send_diagnostics(env, &block)
                raise Core::Transport::HTTP::API::Spec::EndpointNotDefinedError.new('diagnostics', self) if diagnostics.nil?

                diagnostics.call(env, &block)
              end
            end

            class Endpoint < Datadog::Core::Transport::HTTP::API::Endpoint
              attr_reader :encoder

              def initialize(path, encoder)
                super(:post, path)
                @encoder = encoder
              end

              def call(env, &block)
                event_payload = Core::Vendor::Multipart::Post::UploadIO.new(
                  StringIO.new(env.request.parcel.data), 'application/json', 'event.json'
                )
                env.form = {'event' => event_payload}

                super
              end
            end
          end
        end

        HTTP::Client.include(Diagnostics::Client)
      end
    end
  end
end
