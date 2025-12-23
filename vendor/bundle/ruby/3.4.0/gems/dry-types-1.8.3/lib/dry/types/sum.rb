# frozen_string_literal: true

module Dry
  module Types
    # Sum type
    #
    # @api public
    class Sum
      include Composition

      def self.operator = :|

      # @return [Boolean]
      #
      # @api public
      def optional? = primitive?(nil)

      # @param [Object] input
      #
      # @return [Object]
      #
      # @api private
      def call_unsafe(input)
        left.call_safe(input) { right.call_unsafe(input) }
      end

      # @param [Object] input
      #
      # @return [Object]
      #
      # @api private
      def call_safe(input, &block)
        left.call_safe(input) { right.call_safe(input, &block) }
      end

      # @param [Object] input
      #
      # @api public
      def try(input)
        left.try(input) do
          right.try(input) do |failure|
            if block_given?
              yield(failure)
            else
              failure
            end
          end
        end
      end

      # @param [Object] value
      #
      # @return [Boolean]
      #
      # @api private
      def primitive?(value)
        left.primitive?(value) || right.primitive?(value)
      end

      # Manage metadata to the type. If the type is an optional, #meta delegates
      # to the right branch
      #
      # @see [Meta#meta]
      #
      # @api public
      def meta(data = Undefined)
        if Undefined.equal?(data)
          optional? ? right.meta : super
        elsif optional?
          self.class.new(left, right.meta(data), **options)
        else
          super
        end
      end

      # @param [Hash] options
      #
      # @return [Constrained,Sum]
      #
      # @see Builder#constrained
      #
      # @api public
      def constrained(...)
        if optional?
          right.constrained(...).optional
        else
          super
        end
      end
    end
  end
end
