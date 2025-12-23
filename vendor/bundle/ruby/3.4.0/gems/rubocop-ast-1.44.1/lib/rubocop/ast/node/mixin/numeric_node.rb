# frozen_string_literal: true

module RuboCop
  module AST
    # Common functionality for primitive numeric nodes: `int`, `float`, `rational`...
    module NumericNode
      SIGN_REGEX = /\A[+-]/.freeze
      private_constant :SIGN_REGEX

      # Checks whether this is literal has a sign.
      #
      # @example
      #
      #   +42
      #
      # @return [Boolean] whether this literal has a sign.
      def sign?
        source.match(SIGN_REGEX)
      end
    end
  end
end
