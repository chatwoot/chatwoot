# frozen_string_literal: true

module Dry
  module Types
    # Constrained types apply rules to the input
    #
    # @api public
    class Constrained
      include Type
      include Decorator
      include Builder
      include Printable
      include ::Dry::Equalizer(:type, :rule, inspect: false, immutable: true)

      # @return [Dry::Logic::Rule]
      attr_reader :rule

      # @param [Type] type
      #
      # @param [Hash] options
      #
      # @api public
      def initialize(type, **options)
        super
        @rule = options.fetch(:rule)
      end

      # @return [Object]
      #
      # @api private
      def call_unsafe(input)
        result = rule.(input)

        if result.success?
          type.call_unsafe(input)
        else
          raise ConstraintError.new(result, input)
        end
      end

      # @return [Object]
      #
      # @api private
      def call_safe(input, &)
        if rule[input]
          type.call_safe(input, &)
        else
          yield
        end
      end

      # Safe coercion attempt. It is similar to #call with a
      # block given but returns a Result instance with metadata
      # about errors (if any).
      #
      # @overload try(input)
      #   @param [Object] input
      #   @return [Logic::Result]
      #
      # @overload try(input)
      #   @param [Object] input
      #   @yieldparam [Failure] failure
      #   @yieldreturn [Object]
      #   @return [Object]
      #
      # @api public
      def try(input, &)
        result = rule.(input)

        if result.success?
          type.try(input, &)
        else
          failure = failure(input, ConstraintError.new(result, input))
          block_given? ? yield(failure) : failure
        end
      end

      # @param *nullary_rules [Array<Symbol>] a list of rules that do not require an additional
      #   argument (e.g., :odd)
      # @param **unary_rules [Hash] a list of rules that require an additional argument
      #   (e.g., gt: 0)
      #   The parameters are merger to create a rules hash provided to {Types.Rule} and combined
      #   using {&} with previous {#rule}
      #
      # @return [Constrained]
      #
      # @see Dry::Logic::Operators#and
      #
      # @api public
      def constrained(*nullary_rules, **unary_rules)
        nullary_rules_hash = parse_arguments(nullary_rules)

        rules = nullary_rules_hash.merge(unary_rules)

        with(rule: rule & Types.Rule(rules))
      end

      # @return [true]
      #
      # @api public
      def constrained? = true

      # @param [Object] value
      #
      # @return [Boolean]
      #
      # @api public
      def ===(value) = valid?(value)

      # Build lax type. Constraints are not applicable to lax types hence unwrapping
      #
      # @return [Lax]
      # @api public
      def lax = type.lax

      # @see Nominal#to_ast
      # @api public
      def to_ast(meta: true)
        [:constrained, [type.to_ast(meta: meta), rule.to_ast]]
      end

      # @api private
      def constructor_type = type.constructor_type

      private

      # @param [Object] response
      #
      # @return [Boolean]
      #
      # @api private
      def decorate?(response) = super || response.is_a?(Constructor)

      # @param [Array] positional_args
      #
      # @return [Hash]
      #
      # @api private
      def parse_arguments(positional_arguments)
        return positional_arguments.first if positional_arguments.first.is_a?(::Hash)

        positional_arguments.flatten.zip([]).to_h
      end
    end
  end
end
