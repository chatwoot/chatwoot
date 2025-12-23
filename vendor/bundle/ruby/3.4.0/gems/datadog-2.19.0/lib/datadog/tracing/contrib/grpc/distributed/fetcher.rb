# frozen_string_literal: true

require_relative '../../../distributed/fetcher'

module Datadog
  module Tracing
    module Contrib
      module GRPC
        module Distributed
          # Retrieves values from the gRPC metadata.
          # One metadata key can be associated with multiple values.
          #
          # @see https://github.com/grpc/grpc-go/blob/56ac86fa0f3940cb79946ce2c6e56f7ee7ecae84/Documentation/grpc-metadata.md#constructing-metadata
          class Fetcher < Tracing::Distributed::Fetcher
            def [](key)
              # Metadata values are normally integrals but can also be
              # arrays when multiple values are associated with the same key.
              value = super(key)
              value.is_a?(::Array) ? value[0] : value
            end
          end
        end
      end
    end
  end
end
