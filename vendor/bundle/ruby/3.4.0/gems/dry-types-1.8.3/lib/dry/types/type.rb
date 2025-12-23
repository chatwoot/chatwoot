# frozen_string_literal: true

module Dry
  module Types
    # Common Type module denoting an object is a Type
    #
    # @api public
    module Type
      extend ::Dry::Core::Deprecations[:"dry-types"]

      deprecate(:safe, :lax)

      # Whether a value is a valid member of the type
      #
      # @return [Boolean]
      #
      # @api private
      def valid?(input = Undefined)
        call_safe(input) { return false }
        true
      end
      # Anything can be coerced matches
      alias_method :===, :valid?

      # Apply type to a value
      #
      # @overload call(input = Undefined)
      #   Possibly unsafe coercion attempt. If a value doesn't
      #   match the type, an exception will be raised.
      #
      #   @param [Object] input
      #   @return [Object]
      #
      # @overload call(input = Undefined)
      #   When a block is passed, {#call} will never throw an exception on
      #   failed coercion, instead it will call the block.
      #
      #   @param [Object] input
      #   @yieldparam [Object] output Partially coerced value
      #   @return [Object]
      #
      # @api public
      def call(input = Undefined, &)
        if block_given?
          call_safe(input, &)
        else
          call_unsafe(input)
        end
      end
      alias_method :[], :call
    end
  end
end
