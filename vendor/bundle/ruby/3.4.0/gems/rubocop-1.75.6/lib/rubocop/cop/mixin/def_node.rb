# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking def nodes.
    module DefNode
      extend NodePattern::Macros
      include VisibilityHelp

      private

      def non_public?(node)
        non_public_modifier?(node.parent) || preceding_non_public_modifier?(node)
      end

      def preceding_non_public_modifier?(node)
        node_visibility(node) != :public
      end

      # @!method non_public_modifier?(node)
      def_node_matcher :non_public_modifier?, <<~PATTERN
        (send nil? {:private :protected :private_class_method} (any_def ...))
      PATTERN
    end
  end
end
