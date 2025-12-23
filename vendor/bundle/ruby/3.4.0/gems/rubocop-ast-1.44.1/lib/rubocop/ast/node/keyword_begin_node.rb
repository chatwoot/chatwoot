# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `kwbegin` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `kwbegin` nodes within RuboCop.
    class KeywordBeginNode < Node
      # Returns the body of the `kwbegin` block. Returns `self` if the `kwbegin` contains
      # multiple nodes.
      #
      # @return [Node, nil] The body of the `kwbegin`.
      def body
        return unless node_parts.any?

        if rescue_node
          rescue_node.body
        elsif ensure_node
          ensure_node.node_parts[0]
        elsif node_parts.one?
          node_parts[0]
        else
          self
        end
      end

      # Returns the `rescue` node of the `kwbegin` block, if one is present.
      #
      # @return [Node, nil] The `rescue` node within `kwbegin`.
      def ensure_node
        node_parts[0] if node_parts[0]&.ensure_type?
      end

      # Returns the `rescue` node of the `kwbegin` block, if one is present.
      #
      # @return [Node, nil] The `rescue` node within `kwbegin`.
      def rescue_node
        return ensure_node&.rescue_node if ensure_node&.rescue_node

        node_parts[0] if node_parts[0]&.rescue_type?
      end
    end
  end
end
