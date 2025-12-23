# frozen_string_literal: true

module Dry
  module Types
    # Result class used by {Type#try}
    #
    # @api public
    class Result
      include ::Dry::Equalizer(:input, immutable: true)

      # @return [Object]
      attr_reader :input

      # @param [Object] input
      #
      # @api private
      def initialize(input)
        @input = input
      end

      # Success result
      #
      # @api public
      class Success < Result
        # @return [true]
        #
        # @api public
        def success? = true

        # @return [false]
        #
        # @api public
        def failure? = false
      end

      # Failure result
      #
      # @api public
      class Failure < Result
        include ::Dry::Equalizer(:input, :error, immutable: true)

        # @return [#to_s]
        attr_reader :error

        # @param [Object] input
        #
        # @param [#to_s] error
        #
        # @api private
        def initialize(input, error)
          super(input)
          @error = error
        end

        # @return [String]
        #
        # @api private
        def to_s = error.to_s

        # @return [false]
        #
        # @api public
        def success? = false

        # @return [true]
        #
        # @api public
        def failure? = true
      end
    end
  end
end
