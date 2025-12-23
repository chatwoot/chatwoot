# frozen_string_literal: true

module Datadog
  module AppSec
    module Instrumentation
      class Gateway
        # NOTE: This class extracted as-is and will be deprecated
        # Instrumentation gateway middleware
        class Middleware
          attr_reader :key, :block

          def initialize(key, &block)
            @key = key
            @block = block
          end

          def call(stack, env)
            @block.call(stack, env)
          end
        end
      end
    end
  end
end
