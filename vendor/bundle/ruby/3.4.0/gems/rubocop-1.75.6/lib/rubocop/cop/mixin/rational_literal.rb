# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for handling Rational literals.
    module RationalLiteral
      extend NodePattern::Macros

      private

      # @!method rational_literal?(node)
      def_node_matcher :rational_literal?, <<~PATTERN
        (send
          (int _) :/
          (rational _))
      PATTERN
    end
  end
end
