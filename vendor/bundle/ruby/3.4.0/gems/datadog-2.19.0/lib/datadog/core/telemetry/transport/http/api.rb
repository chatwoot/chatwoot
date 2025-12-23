# frozen_string_literal: true

require_relative '../../../encoding'
require_relative '../../../transport/http/api/map'
require_relative '../../../transport/http/api/instance'
require_relative '../../../transport/http/api/spec'
require_relative 'telemetry'

module Datadog
  module Core
    module Telemetry
      module Transport
        module HTTP
          # Namespace for API components
          module API
            # Default API versions
            AGENT_TELEMETRY = 'agent_telemetry'
            AGENTLESS_TELEMETRY = 'agentless_telemetry'

            module_function

            def defaults
              Datadog::Core::Transport::HTTP::API::Map[
                AGENT_TELEMETRY => Telemetry::API::Spec.new do |s|
                  s.telemetry = Telemetry::API::Endpoint.new(
                    '/telemetry/proxy/api/v2/apmtelemetry',
                    Core::Encoding::JSONEncoder,
                  )
                end,
                AGENTLESS_TELEMETRY => Telemetry::API::Spec.new do |s|
                  s.telemetry = Telemetry::API::Endpoint.new(
                    '/api/v2/apmtelemetry',
                    Core::Encoding::JSONEncoder,
                  )
                end,
              ]
            end
          end
        end
      end
    end
  end
end
