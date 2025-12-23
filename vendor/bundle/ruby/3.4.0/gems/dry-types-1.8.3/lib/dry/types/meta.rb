# frozen_string_literal: true

module Dry
  module Types
    # Storage for meta-data
    #
    # @api public
    module Meta
      def initialize(*args, meta: EMPTY_HASH, **options)
        super(*args, **options)
        @meta = meta.freeze
      end

      # @param options [Hash] new_options
      #
      # @return [Type]
      #
      # @api public
      def with(**options) = super(meta: @meta, **options)

      # @overload meta
      #   @return [Hash] metadata associated with type
      #
      # @overload meta(data)
      #   @param [Hash] new metadata to merge into existing metadata
      #   @return [Type] new type with added metadata
      #
      # @api public
      def meta(data = Undefined)
        if Undefined.equal?(data)
          @meta
        elsif data.empty?
          self
        else
          with(meta: @meta.merge(data))
        end
      end

      # Resets meta
      #
      # @return [Dry::Types::Type]
      #
      # @api public
      def pristine = with(meta: EMPTY_HASH)
    end
  end
end
