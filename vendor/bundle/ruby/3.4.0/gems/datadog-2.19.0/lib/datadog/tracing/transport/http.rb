# frozen_string_literal: true

require_relative '../../core/environment/container'
require_relative '../../core/environment/ext'
require_relative '../../core/transport/ext'
require_relative '../../core/transport/http'
require_relative 'http/api'
require_relative '../../../datadog/version'

module Datadog
  module Tracing
    module Transport
      # Namespace for HTTP transport components
      module HTTP
        module_function

        # Builds a new Transport::HTTP::Client with default settings
        # Pass a block to override any settings.
        def default(
          agent_settings:,
          logger: Datadog.logger,
          api_version: nil,
          headers: nil
        )
          Core::Transport::HTTP.build(
            api_instance_class: Traces::API::Instance,
            agent_settings: agent_settings,
            logger: logger,
            api_version: api_version,
            headers: headers
          ) do |transport|
            apis = API.defaults

            transport.api API::V4, apis[API::V4], fallback: API::V3, default: true
            transport.api API::V3, apis[API::V3]

            # Call block to apply any customization, if provided
            yield(transport) if block_given?
          end.to_transport(Transport::Traces::Transport)
        end
      end
    end
  end
end
