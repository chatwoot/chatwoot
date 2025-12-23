# frozen_string_literal: true

module Dry
  module Types
    # Hash type exposes additional APIs for working with schema hashes
    #
    # @api public
    class Hash < Nominal
      class Constructor < ::Dry::Types::Constructor
        # @api private
        def constructor_type = ::Dry::Types::Hash::Constructor

        # @return [Lax]
        #
        # @api public
        def lax = Lax.new(type.lax.constructor(fn, meta: meta))

        # @see Dry::Types::Array#of
        #
        # @api public
        def schema(...) = type.schema(...).constructor(fn, meta: meta)
      end
    end
  end
end
