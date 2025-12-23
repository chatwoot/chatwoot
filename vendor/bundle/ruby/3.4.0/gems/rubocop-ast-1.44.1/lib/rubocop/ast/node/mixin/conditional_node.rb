# frozen_string_literal: true

module RuboCop
  module AST
    # Common functionality for nodes that have conditions:
    # `if`, `while`, `until`, `case`.
    # This currently doesn't include `when` nodes, because they have multiple
    # conditions, and need to be checked for that.
    module ConditionalNode
      # Checks whether the condition of the node is written on a single line.
      #
      # @return [Boolean] whether the condition is on a single line
      def single_line_condition?
        loc.keyword.line == condition.source_range.line
      end

      # Checks whether the condition of the node is written on more than
      # one line.
      #
      # @return [Boolean] whether the condition is on more than one line
      def multiline_condition?
        !single_line_condition?
      end

      # Returns the condition of the node. This works together with each node's
      # custom destructuring method to select the correct part of the node.
      #
      # @return [Node, nil] the condition of the node
      def condition
        node_parts[0]
      end

      # Returns the body associated with the condition. This works together with
      # each node's custom destructuring method to select the correct part of
      # the node.
      #
      # @note For `if` nodes, this is the truthy branch.
      #
      # @return [Node, nil] the body of the node
      def body
        node_parts[1]
      end
    end
  end
end
