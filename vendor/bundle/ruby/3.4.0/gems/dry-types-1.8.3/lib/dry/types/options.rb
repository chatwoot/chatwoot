# frozen_string_literal: true

module Dry
  module Types
    # Common API for types with options
    #
    # @api private
    module Options
      # @return [Hash]
      attr_reader :options

      # @see Nominal#initialize
      #
      # @api private
      def initialize(*args, **options)
        @__args__ = args.freeze
        @options = options.freeze
      end

      # @param [Hash] new_options
      #
      # @return [Type]
      #
      # @api private
      def with(**new_options)
        self.class.new(*@__args__, **options, **new_options)
      end
    end
  end
end
