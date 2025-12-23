# frozen_string_literal: true

module Dry
  module Types
    # @api public
    class Constructor < Nominal
      module Wrapper
        # @return [Object]
        #
        # @api private
        def call_safe(input, &) = fn.(input, type, &)

        # @return [Object]
        #
        # @api private
        def call_unsafe(input) = fn.(input, type)

        # @param [Object] input
        # @param [#call,nil] block
        #
        # @return [Logic::Result, Types::Result]
        # @return [Object] if block given and try fails
        #
        # @api public
        def try(input, &)
          value = fn.(input, type)
        rescue CoercionError => e
          failure = failure(input, e)
          block_given? ? yield(failure) : failure
        else
          type.try(value, &)
        end

        # Define a constructor for the type
        #
        # @param [#call,nil] constructor
        # @param [Hash] options
        # @param [#call,nil] block
        #
        # @return [Constructor]
        #
        # @api public
        define_method(:constructor, Builder.instance_method(:constructor))
        alias_method :append, :constructor
        alias_method :>>, :constructor

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
          prep_fn = Function[new_fn || block]

          decorated =
            if prep_fn.wrapper?
              type.constructor(prep_fn, **options)
            else
              type.prepend(prep_fn, **options)
            end

          __new__(decorated)
        end
        alias_method :<<, :prepend

        # @return [Constructor]
        #
        # @api public
        def lax
          # return self back because wrapping function
          # can handle failed type check
          self
        end

        private

        # Replace underlying type
        #
        # @api private
        def __new__(type) = self.class.new(type, *@__args__.drop(1), **@options)
      end
    end
  end
end
