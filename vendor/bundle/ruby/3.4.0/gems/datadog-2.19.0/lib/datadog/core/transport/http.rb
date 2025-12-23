# frozen_string_literal: true

require_relative 'http/builder'
require_relative 'http/adapters/net'
require_relative 'http/adapters/unix_socket'
require_relative 'http/adapters/test'

module Datadog
  module Core
    module Transport
      # HTTP transport
      module HTTP
        # Add adapters to registry
        Builder::REGISTRY.set(
          Transport::HTTP::Adapters::Net,
          Core::Configuration::Ext::Agent::HTTP::ADAPTER
        )
        Builder::REGISTRY.set(
          Transport::HTTP::Adapters::Test,
          Transport::Ext::Test::ADAPTER
        )
        Builder::REGISTRY.set(
          Transport::HTTP::Adapters::UnixSocket,
          Transport::Ext::UnixSocket::ADAPTER
        )

        module_function

        # Helper function that delegates to Builder.new
        # but is under HTTP namespace so that client code requires this file
        # to get the adapters configured, and not the builder directly.
        def build(api_instance_class:, agent_settings:, logger: Datadog.logger, api_version: nil, headers: nil, &block)
          Builder.new(api_instance_class: api_instance_class, logger: logger) do |transport|
            transport.adapter(agent_settings)
            transport.headers(default_headers)

            # The caller must define APIs before we set the default API.
            yield transport

            # Apply any settings given by options
            transport.default_api = api_version if api_version
            transport.headers(headers) if headers
          end
        end

        def default_headers
          {
            Datadog::Core::Transport::Ext::HTTP::HEADER_CLIENT_COMPUTED_TOP_LEVEL => '1',
            Datadog::Core::Transport::Ext::HTTP::HEADER_META_LANG =>
              Datadog::Core::Environment::Ext::LANG,
            Datadog::Core::Transport::Ext::HTTP::HEADER_META_LANG_VERSION =>
              Datadog::Core::Environment::Ext::LANG_VERSION,
            Datadog::Core::Transport::Ext::HTTP::HEADER_META_LANG_INTERPRETER =>
              Datadog::Core::Environment::Ext::LANG_INTERPRETER,
            Datadog::Core::Transport::Ext::HTTP::HEADER_META_LANG_INTERPRETER_VENDOR =>
              Core::Environment::Ext::LANG_ENGINE,
            Datadog::Core::Transport::Ext::HTTP::HEADER_META_TRACER_VERSION =>
              Datadog::Core::Environment::Ext::GEM_DATADOG_VERSION
          }.tap do |headers|
            # Add container ID, if present.
            if (container_id = Datadog::Core::Environment::Container.container_id)
              headers[Datadog::Core::Transport::Ext::HTTP::HEADER_CONTAINER_ID] = container_id
            end
            # TODO: inject configuration rather than reading from global here
            unless Datadog.configuration.apm.tracing.enabled
              # Sending this header to the agent will disable metrics computation (and billing) on the agent side
              # by pretending it has already been done on the library side.
              headers[Datadog::Core::Transport::Ext::HTTP::HEADER_CLIENT_COMPUTED_STATS] = 'yes'
            end
          end
        end
      end
    end
  end
end
