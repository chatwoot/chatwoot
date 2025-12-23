# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `class` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `class` nodes within RuboCop.
    class ClassNode < Node
      # The identifier for this `class` node.
      #
      # @return [Node] the identifier of the class
      def identifier
        node_parts[0]
      end

      # The parent class for this `class` node.
      #
      # @return [Node, nil] the parent class of the class
      def parent_class
        node_parts[1]
      end

      # The body of this `class` node.
      #
      # @return [Node, nil] the body of the class
      def body
        node_parts[2]
      end
    end
  end
end
