# frozen_string_literal: true

module Dry
  module Types
    # @api public
    class Array < Nominal
      # @api private
      class Constructor < ::Dry::Types::Constructor
        # @api private
        def constructor_type = ::Dry::Types::Array::Constructor

        # @return [Lax]
        #
        # @api public
        def lax = Lax.new(type.lax.constructor(fn, meta: meta))

        # @see Dry::Types::Array#of
        #
        # @api public
        def of(member) = type.of(member).constructor(fn, meta: meta)
      end
    end
  end
end
