# frozen_string_literal: true

require_relative 'helpers'

module Datadog
  module Tracing
    module Distributed
      # Common fetcher that retrieves fields from a Hash data input
      class Fetcher
        # @param data [Hash]
        def initialize(data)
          @data = data
        end

        def [](key)
          @data[key]
        end
      end
    end
  end
end
