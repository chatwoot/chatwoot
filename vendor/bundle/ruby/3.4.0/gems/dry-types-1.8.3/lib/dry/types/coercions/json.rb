# frozen_string_literal: true

require "date"
require "bigdecimal"
require "bigdecimal/util"
require "time"

module Dry
  module Types
    module Coercions
      # JSON-specific coercions
      #
      # @api public
      module JSON
        extend Coercions

        # @param [Object] input
        #
        # @return [nil] if the input is nil
        #
        # @raise CoercionError
        #
        # @api public
        def self.to_nil(input, &)
          if input.nil?
            nil
          elsif block_given?
            yield
          else
            raise CoercionError, "#{input.inspect} is not nil"
          end
        end

        # @param [#to_d, Object] input
        #
        # @return [BigDecimal,nil]
        #
        # @raise CoercionError
        #
        # @api public
        def self.to_decimal(input, &)
          if input.is_a?(::Float)
            input.to_d
          else
            BigDecimal(input)
          end
        rescue ::ArgumentError, ::TypeError
          if block_given?
            yield
          else
            raise CoercionError, "#{input} cannot be coerced to decimal"
          end
        end
      end
    end
  end
end
