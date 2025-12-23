# frozen_string_literal: true

module Datadog
  module Core
    module Utils
      # Generates values from a consistent sequence
      class Sequence
        def initialize(seed = 0, &block)
          @seed = seed
          @current = seed
          @next_item = block
        end

        def next
          next_item = @next_item ? @next_item.call(@current) : @current
          @current += 1
          next_item
        end

        def reset!
          @current = @seed
        end
      end
    end
  end
end
