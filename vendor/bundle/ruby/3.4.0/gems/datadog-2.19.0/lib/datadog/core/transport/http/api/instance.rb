# frozen_string_literal: true

module Datadog
  module Core
    module Transport
      module HTTP
        module API
          # An API configured with adapter and routes
          class Instance
            # Raised when an endpoint is invoked on an API that is not the
            # of expected API class for that endpoint.
            class EndpointNotSupportedError < StandardError
              attr_reader :spec, :endpoint_name

              def initialize(endpoint_name, spec)
                @spec = spec
                @endpoint_name = endpoint_name

                super(message)
              end

              def message
                "#{endpoint_name} not supported for this API!"
              end
            end

            attr_reader \
              :adapter,
              :headers,
              :spec

            def initialize(spec, adapter, options = {})
              @spec = spec
              @adapter = adapter
              @headers = options.fetch(:headers, {})
            end

            def encoder
              spec.encoder
            end

            def call(env)
              # Add headers to request env, unless empty.
              env.headers.merge!(headers) unless headers.empty?

              # Send request env to the adapter.
              adapter.call(env)
            end
          end
        end
      end
    end
  end
end
