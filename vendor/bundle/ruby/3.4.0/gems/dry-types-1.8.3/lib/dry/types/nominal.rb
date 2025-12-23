# frozen_string_literal: true

module Dry
  module Types
    # Nominal types define a primitive class and do not apply any constructors or constraints
    #
    # Use these types for annotations and the base for building more complex types on top of them.
    #
    # @api public
    class Nominal
      include Type
      include Options
      include Meta
      include Builder
      include Printable
      include ::Dry::Equalizer(:primitive, :options, :meta, inspect: false, immutable: true)

      # @return [Class]
      attr_reader :primitive

      # @param [Class] primitive
      #
      # @return [Type]
      #
      # @api private
      def self.[](primitive)
        if primitive == ::Array
          Types::Array
        elsif primitive == ::Hash
          Types::Hash
        else
          self
        end
      end

      ALWAYS = proc { true }

      # @param [Type,Class] primitive
      # @param [Hash] options
      #
      # @api private
      def initialize(primitive, **options)
        super
        @primitive = primitive
        freeze
      end

      # @return [String]
      #
      # @api public
      def name = primitive.name

      # @return [false]
      #
      # @api public
      def default? = false

      # @return [false]
      #
      # @api public
      def constrained? = false

      # @return [false]
      #
      # @api public
      def optional? = false

      # @param [BasicObject] input
      #
      # @return [BasicObject]
      #
      # @api private
      def call_unsafe(input) = input

      # @param [BasicObject] input
      #
      # @return [BasicObject]
      #
      # @api private
      def call_safe(input, &) = input

      # @param [Object] input
      #
      # @yieldparam [Failure] failure
      # @yieldreturn [Result]
      #
      # @return [Result,Logic::Result] when a block is not provided
      # @return [nil] otherwise
      #
      # @api public
      def try(input, &) = success(input)

      # @param (see Dry::Types::Success#initialize)
      #
      # @return [Result::Success]
      #
      # @api public
      def success(input) = Result::Success.new(input)

      # @param (see Failure#initialize)
      #
      # @return [Result::Failure]
      #
      # @api public
      def failure(input, error)
        raise ::ArgumentError, "error must be a CoercionError" unless error.is_a?(CoercionError)

        Result::Failure.new(input, error)
      end

      # Checks whether value is of a #primitive class
      #
      # @param [Object] value
      #
      # @return [Boolean]
      #
      # @api public
      def primitive?(value) = value.is_a?(primitive)

      # @api private
      def coerce(input, &)
        if primitive?(input)
          input
        elsif block_given?
          yield
        else
          raise CoercionError, "#{input.inspect} must be an instance of #{primitive}"
        end
      end

      # @api private
      def try_coerce(input)
        result = success(input)

        coerce(input) do
          result = failure(
            input,
            CoercionError.new("#{input.inspect} must be an instance of #{primitive}")
          )
        end

        if block_given?
          yield(result)
        else
          result
        end
      end

      # Return AST representation of a type nominal
      #
      # @return [Array]
      #
      # @api public
      def to_ast(meta: true)
        [:nominal, [primitive, meta ? self.meta : EMPTY_HASH]]
      end

      # Return self. Nominal types are lax by definition
      #
      # @return [Nominal]
      #
      # @api public
      def lax = self

      # Wrap the type with a proc
      #
      # @return [Proc]
      #
      # @api public
      def to_proc = ALWAYS
    end

    extend ::Dry::Core::Deprecations[:"dry-types"]
    Definition = Nominal
    deprecate_constant(:Definition, message: "Nominal")
  end
end
