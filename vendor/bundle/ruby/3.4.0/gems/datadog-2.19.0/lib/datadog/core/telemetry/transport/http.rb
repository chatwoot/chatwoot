# frozen_string_literal: true

require_relative 'telemetry'
require_relative 'http/api'
require_relative '../../transport/http'

module Datadog
  module Core
    module Telemetry
      module Transport
        # Namespace for HTTP transport components
        module HTTP
          module_function

          # Builds a new Transport::HTTP::Client with default settings
          # Pass a block to override any settings.
          def agentless_telemetry(
            agent_settings:,
            logger:,
            api_key: nil,
            api_version: nil,
            headers: nil
          )
            Core::Transport::HTTP.build(api_instance_class: Telemetry::API::Instance,
              logger: logger,
              agent_settings: agent_settings,
              api_version: api_version,
              headers: headers) do |transport|
              apis = API.defaults

              transport.api API::AGENTLESS_TELEMETRY, apis[API::AGENTLESS_TELEMETRY]

              # Call block to apply any customization, if provided
              yield(transport) if block_given?
            end.to_transport(Core::Telemetry::Transport::Telemetry::Transport).tap do |transport|
              transport.api_key = api_key
            end
          end

          # Builds a new Transport::HTTP::Client with default settings
          # Pass a block to override any settings.
          def agent_telemetry(
            agent_settings:,
            logger:,
            api_version: nil,
            headers: nil
          )
            Core::Transport::HTTP.build(api_instance_class: Telemetry::API::Instance,
              logger: logger,
              agent_settings: agent_settings, api_version: api_version, headers: headers) do |transport|
              apis = API.defaults

              transport.api API::AGENT_TELEMETRY, apis[API::AGENT_TELEMETRY]

              # Call block to apply any customization, if provided
              yield(transport) if block_given?
            end.to_transport(Core::Telemetry::Transport::Telemetry::Transport)
          end
        end
      end
    end
  end
end
