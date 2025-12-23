# frozen_string_literal: true

require_relative '../../configuration/agent_settings'
require_relative 'adapters/registry'
require_relative 'api/map'

module Datadog
  module Core
    module Transport
      module HTTP
        # Builds new instances of Transport::HTTP::Client
        class Builder
          REGISTRY = Datadog::Core::Transport::HTTP::Adapters::Registry.new

          attr_reader \
            :api_instance_class,
            :apis,
            :api_options,
            :default_adapter,
            :default_api,
            :default_headers,
            :logger

          def initialize(api_instance_class:, logger: Datadog.logger)
            # Global settings
            @default_adapter = nil
            @default_headers = {}

            # Client settings
            @apis = Datadog::Core::Transport::HTTP::API::Map.new
            @default_api = nil

            # API settings
            @api_options = {}

            @api_instance_class = api_instance_class
            @logger = logger

            yield(self) if block_given?
          end

          def adapter(config, *args, **kwargs)
            @default_adapter = case config
            when Core::Configuration::AgentSettings
              registry_klass = REGISTRY.get(config.adapter)
              raise UnknownAdapterError, config.adapter if registry_klass.nil?

              registry_klass.build(config)
            when Symbol
              registry_klass = REGISTRY.get(config)
              raise UnknownAdapterError, config if registry_klass.nil?

              registry_klass.new(*args, **kwargs)
            else
              config
            end
          end

          def headers(values = {})
            @default_headers.merge!(values)
          end

          # Adds a new API to the client
          # Valid options:
          #  - :adapter
          #  - :default
          #  - :fallback
          #  - :headers
          def api(key, spec, options = {})
            options = options.dup

            # Copy spec into API map
            @apis[key] = spec

            # Apply as default API, if specified to do so.
            @default_api = key if options.delete(:default) || @default_api.nil?

            # Save all other settings for initialization
            (@api_options[key] ||= {}).merge!(options)
          end

          def default_api=(key)
            raise UnknownApiError, key unless @apis.key?(key)

            @default_api = key
          end

          def to_transport(klass)
            raise NoDefaultApiError if @default_api.nil?

            klass.new(to_api_instances, @default_api, logger: logger)
          end

          def to_api_instances
            raise NoApisError if @apis.empty?

            @apis.inject(Datadog::Core::Transport::HTTP::API::Map.new) do |instances, (key, spec)|
              instances.tap do
                api_options = @api_options[key].dup

                # Resolve the adapter to use for this API
                adapter = api_options.delete(:adapter) || @default_adapter
                raise NoAdapterForApiError, key if adapter.nil?

                # Resolve fallback and merge headers
                fallback = api_options.delete(:fallback)
                api_options[:headers] = @default_headers.merge((api_options[:headers] || {}))

                # Add API::Instance with all settings
                instances[key] = api_instance_class.new(
                  spec,
                  adapter,
                  api_options
                )

                # Configure fallback, if provided.
                instances.with_fallbacks(key => fallback) unless fallback.nil?
              end
            end
          end

          # Raised when the API key does not match known APIs.
          class UnknownApiError < StandardError
            attr_reader :key

            def initialize(key)
              super()

              @key = key
            end

            def message
              "Unknown transport API '#{key}'!"
            end
          end

          # Raised when the identifier cannot be matched to an adapter.
          class UnknownAdapterError < StandardError
            attr_reader :type

            def initialize(type)
              super()

              @type = type
            end

            def message
              "Unknown transport adapter '#{type}'!"
            end
          end

          # Raised when an adapter cannot be resolved for an API instance.
          class NoAdapterForApiError < StandardError
            attr_reader :key

            def initialize(key)
              super()

              @key = key
            end

            def message
              "No adapter resolved for transport API '#{key}'!"
            end
          end

          # Raised when built without defining APIs.
          class NoApisError < StandardError
            def message
              'No APIs configured for transport!'
            end
          end

          # Raised when client built without defining a default API.
          class NoDefaultApiError < StandardError
            def message
              'No default API configured for transport!'
            end
          end
        end
      end
    end
  end
end
