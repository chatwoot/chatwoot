# frozen_string_literal: true

module Dry
  module Types
    # Lax types rescue from type-related errors when constructors fail
    #
    # @api public
    class Lax
      include Type
      include Decorator
      include Builder
      include Printable
      include ::Dry::Equalizer(:type, inspect: false, immutable: true)

      undef :options, :constructor, :<<, :>>, :prepend, :append

      # @param [Object] input
      #
      # @return [Object]
      #
      # @api public
      def call(input, &)
        type.call_safe(input) { |output = input| output }
      end
      alias_method :[], :call
      alias_method :call_safe, :call
      alias_method :call_unsafe, :call

      # @param [Object] input
      # @param [#call,nil] block
      #
      # @yieldparam [Failure] failure
      # @yieldreturn [Result]
      #
      # @return [Result,Logic::Result]
      #
      # @api public
      def try(input, &) = type.try(input, &)

      # @see Nominal#to_ast
      #
      # @api public
      def to_ast(meta: true) = [:lax, type.to_ast(meta: meta)]

      # @return [Lax]
      #
      # @api public
      def lax = self

      private

      # @param [Object, Dry::Types::Constructor] response
      #
      # @return [Boolean]
      #
      # @api private
      def decorate?(response)
        super || response.is_a?(type.constructor_type)
      end
    end

    extend ::Dry::Core::Deprecations[:"dry-types"]
    Safe = Lax
    deprecate_constant(:Safe)
  end
end
