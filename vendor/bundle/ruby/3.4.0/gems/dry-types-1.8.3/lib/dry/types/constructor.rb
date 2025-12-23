# frozen_string_literal: true

module Dry
  module Types
    # Constructor types apply a function to the input that is supposed to return
    # a new value. Coercion is a common use case for constructor types.
    #
    # @api public
    class Constructor < Nominal
      include ::Dry::Equalizer(:type, :options, inspect: false, immutable: true)

      # @return [#call]
      attr_reader :fn

      # @return [Type]
      attr_reader :type

      undef :constrained?, :meta, :optional?, :primitive, :default?, :name

      # @param [Builder, Object] input
      # @param [Hash] options
      # @param [#call, nil] block
      #
      # @api public
      def self.new(input, fn: Undefined, **options, &block)
        type = input.is_a?(Builder) ? input : Nominal.new(input)
        super(type, **options, fn: Function[Undefined.default(fn, block)])
      end

      # @param [Builder, Object] input
      # @param [Hash] options
      # @param [#call, nil] block
      #
      # @api public
      def self.[](type, fn:, **options)
        function = Function[fn]

        if function.wrapper?
          wrapper_type.new(type, fn: function, **options)
        else
          new(type, fn: function, **options)
        end
      end

      # @api private
      def self.wrapper_type
        @wrapper_type ||=
          if self < Wrapper
            self
          else
            const_set(:Wrapping, ::Class.new(self).include(Wrapper))
          end
      end

      # Instantiate a new constructor type instance
      #
      # @param [Type] type
      # @param [Function] fn
      # @param [Hash] options
      #
      # @api private
      def initialize(type, fn: nil, **options)
        @type = type
        @fn = fn

        super(type, **options, fn: fn)
      end

      # @return [Object]
      #
      # @api private
      def call_safe(input)
        coerced = fn.(input) { |output = input| return yield(output) }
        type.call_safe(coerced) { |output = coerced| yield(output) }
      end

      # @return [Object]
      #
      # @api private
      def call_unsafe(input) = type.call_unsafe(fn.(input))

      # @param [Object] input
      # @param [#call,nil] block
      #
      # @return [Logic::Result, Types::Result]
      # @return [Object] if block given and try fails
      #
      # @api public
      def try(input, &)
        value = fn.(input)
      rescue CoercionError => e
        failure = failure(input, e)
        block_given? ? yield(failure) : failure
      else
        type.try(value, &)
      end

      # Build a new constructor by appending a block to the coercion function
      #
      # @param [#call, nil] new_fn
      # @param [Hash] options
      # @param [#call, nil] block
      #
      # @return [Constructor]
      #
      # @api public
      def constructor(new_fn = nil, **options, &block)
        next_fn = Function[new_fn || block]

        if next_fn.wrapper?
          self.class.wrapper_type.new(with(**options), fn: next_fn)
        else
          with(**options, fn: fn >> next_fn)
        end
      end
      alias_method :append, :constructor
      alias_method :>>, :constructor

      # @return [Class]
      #
      # @api private
      def constrained_type = Constrained::Coercible

      # @see Nominal#to_ast
      #
      # @api public
      def to_ast(meta: true)
        [:constructor, [type.to_ast(meta: meta), fn.to_ast]]
      end

      # Build a new constructor by prepending a block to the coercion function
      #
      # @param [#call, nil] new_fn
      # @param [Hash] options
      # @param [#call, nil] block
      #
      # @return [Constructor]
      #
      # @api public
      def prepend(new_fn = nil, **options, &block)
        with(**options, fn: fn << (new_fn || block))
      end
      alias_method :<<, :prepend

      # Build a lax type
      #
      # @return [Lax]
      # @api public
      def lax = Lax.new(constructor_type[type.lax, **options])

      # Wrap the type with a proc
      #
      # @return [Proc]
      #
      # @api public
      def to_proc = proc { self.(_1) }

      private

      # @param [Symbol] meth
      # @param [Boolean] include_private
      # @return [Boolean]
      #
      # @api private
      def respond_to_missing?(meth, include_private = false)
        super || type.respond_to?(meth)
      end

      # Delegates missing methods to {#type}
      #
      # @param [Symbol] method
      # @param [Array] args
      # @param [#call, nil] block
      #
      # @api private
      def method_missing(method, ...)
        if type.respond_to?(method)
          response = type.public_send(method, ...)

          if response.is_a?(Type) && response.instance_of?(type.class)
            response.constructor_type[response, **options]
          else
            response
          end
        else
          super
        end
      end
    end
  end
end
