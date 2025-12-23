# frozen_string_literal: true

module Dry
  module Schema
    class Message
      module Or
        # A message type used by OR operations
        #
        # @abstract
        #
        # @api private
        class Abstract
          # @api private
          attr_reader :left

          # @api private
          attr_reader :right

          # @api private
          def initialize(left, right)
            @left = left
            @right = right
          end
        end
      end
    end
  end
end
