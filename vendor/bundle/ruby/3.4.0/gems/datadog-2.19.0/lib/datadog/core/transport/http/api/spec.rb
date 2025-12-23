# frozen_string_literal: true

module Datadog
  module Core
    module Transport
      module HTTP
        module API
          # Specification for an HTTP API
          # Defines behaviors without specific configuration details.
          class Spec
            # Raised when an endpoint is invoked on an API that did not
            # define that endpoint.
            class EndpointNotDefinedError < StandardError
              attr_reader :spec, :endpoint_name

              def initialize(endpoint_name, spec)
                @spec = spec
                @endpoint_name = endpoint_name

                super(message)
              end

              def message
                "No #{endpoint_name} endpoint is defined for API specification!"
              end
            end

            def initialize
              yield(self) if block_given?
            end
          end
        end
      end
    end
  end
end
