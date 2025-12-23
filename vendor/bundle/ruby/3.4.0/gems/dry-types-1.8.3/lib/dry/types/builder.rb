# frozen_string_literal: true

module Dry
  module Types
    # Common API for building types and composition
    #
    # @api public
    module Builder
      include ::Dry::Core::Constants

      # @return [Class]
      #
      # @api private
      def constrained_type = Constrained

      # @return [Class]
      #
      # @api private
      def constructor_type = Constructor

      # Compose two types into a Sum type
      #
      # @param [Type] other
      #
      # @return [Sum, Sum::Constrained]
      #
      # @api private
      def |(other) = compose(other, Sum)

      # Compose two types into an Intersection type
      #
      # @param [Type] other
      #
      # @return [Intersection, Intersection::Constrained]
      #
      # @api private
      def &(other) = compose(other, Intersection)

      # Compose two types into an Implication type
      #
      # @param [Type] other
      #
      # @return [Implication, Implication::Constrained]
      #
      # @api private
      def >(other) = compose(other, Implication)

      # Turn a type into an optional type
      #
      # @return [Sum]
      #
      # @api public
      def optional = Types["nil"] | self

      # Turn a type into a constrained type
      #
      # @param [Hash] options constraining rule (see {Types.Rule})
      #
      # @return [Constrained]
      #
      # @api public
      def constrained(...)
        constrained_type.new(self, rule: Types.Rule(...))
      end

      # Turn a type into a type with a default value
      #
      # @param [Object] input
      # @option [Boolean] shared Whether it's safe to share the value across type applications
      # @param [#call,nil] block
      #
      # @raise [ConstraintError]
      #
      # @return [Default]
      #
      # @api public
      def default(input = Undefined, options = EMPTY_HASH, &block)
        unless input.frozen? || options[:shared]
          where = Core::Deprecations::STACK.()
          Core::Deprecations.warn(
            "#{input.inspect} is mutable. " \
            "Be careful: types will return the same instance of the default " \
            "value every time. Call `.freeze` when setting the default " \
            "or pass `shared: true` to discard this warning." \
            "\n#{where}",
            tag: :"dry-types"
          )
        end

        value = Undefined.default(input, block)
        type = Default[value].new(self, value)

        if !type.callable? && !valid?(value)
          raise ConstraintError.new(
            "default value #{value.inspect} violates constraints",
            value
          )
        else
          type
        end
      end

      # Define an enum on top of the existing type
      #
      # @param [Array] values
      #
      # @return [Enum]
      #
      # @api public
      def enum(*values)
        mapping =
          if values.length == 1 && values[0].is_a?(::Hash)
            values[0]
          else
            values.zip(values).to_h
          end

        Enum.new(constrained(included_in: mapping.keys), mapping: mapping)
      end

      # Turn a type into a lax type that will rescue from type-errors and
      # return the original input
      #
      # @return [Lax]
      #
      # @api public
      def lax = Lax.new(self)

      # Define a constructor for the type
      #
      # @param [#call,nil] constructor
      # @param [Hash] options
      # @param [#call,nil] block
      #
      # @return [Constructor]
      #
      # @api public
      def constructor(constructor = nil, **options, &block)
        constructor_type[with(**options), fn: constructor || block]
      end
      alias_method :append, :constructor
      alias_method :prepend, :constructor
      alias_method :>>, :constructor
      alias_method :<<, :constructor

      # Use the given value on type mismatch
      #
      # @param [Object] value
      # @option [Boolean] shared Whether it's safe to share the value across type applications
      # @param [#call,nil] fallback
      #
      # @return [Constructor]
      #
      # @api public
      def fallback(value = Undefined, shared: false, &_fallback) # rubocop:disable Metrics/PerceivedComplexity
        if Undefined.equal?(value) && !block_given?
          raise ::ArgumentError, "fallback value or a block must be given"
        end

        if !block_given? && !valid?(value)
          raise ConstraintError.new(
            "fallback value #{value.inspect} violates constraints",
            value
          )
        end

        unless value.frozen? || shared
          where = Core::Deprecations::STACK.()
          Core::Deprecations.warn(
            "#{value.inspect} is mutable. " \
            "Be careful: types will return the same instance of the fallback " \
            "value every time. Call `.freeze` when setting the fallback " \
            "or pass `shared: true` to discard this warning." \
            "\n#{where}",
            tag: :"dry-types"
          )
        end

        constructor do |input, type, &|
          type.(input) do |output = input|
            if block_given?
              yield(output)
            else
              value
            end
          end
        end
      end

      private

      # @api private
      def compose(other, composition_class)
        klass =
          if constrained? && other.constrained?
            composition_class::Constrained
          else
            composition_class
          end

        klass.new(self, other)
      end
    end
  end
end
