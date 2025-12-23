# frozen_string_literal: true

module Dry
  module Types
    # Any is a nominal type that defines Object as the primitive class
    #
    # This type is useful in places where you can't be specific about the type
    # and anything is acceptable.
    #
    # @api public
    class AnyClass < Nominal
      def self.name = "Any"

      # @api private
      def initialize(**options)
        super(::Object, **options)
      end

      # @return [String]
      #
      # @api public
      def name = "Any"

      # @param [Hash] new_options
      #
      # @return [Type]
      #
      # @api public
      def with(**new_options)
        self.class.new(**options, meta: @meta, **new_options)
      end

      # @return [Array]
      #
      # @api public
      def to_ast(meta: true) = [:any, meta ? self.meta : EMPTY_HASH]
    end

    Any = AnyClass.new
  end
end
