# frozen_string_literal: true

module RuboCop
  module AST
    # Common functionality for primitive literal nodes: `sym`, `str`,
    # `int`, `float`, ...
    module Descendence
      # Calls the given block for each child node.
      # If no block is given, an `Enumerator` is returned.
      #
      # Note that this is different from `node.children.each { |child| ... }`
      # which yields all children including non-node elements.
      #
      # @overload each_child_node
      #   Yield all nodes.
      # @overload each_child_node(type, ...)
      #   Yield only nodes matching any of the types.
      #   @param [Symbol] type a node type
      # @yieldparam [Node] node each child node
      # @return [self] if a block is given
      # @return [Enumerator] if no block is given
      def each_child_node(*types)
        return to_enum(__method__, *types) unless block_given?

        children.each do |child|
          next unless child.is_a?(::AST::Node)

          yield child if types.empty? || child.type?(*types)
        end

        self
      end

      # Returns an array of child nodes.
      # This is a shorthand for `node.each_child_node.to_a`.
      #
      # @return [Array<Node>] an array of child nodes
      def child_nodes
        # Iterate child nodes directly to avoid allocating an Enumerator.
        nodes = []
        each_child_node { |node| nodes << node }
        nodes
      end

      # Calls the given block for each descendant node with depth first order.
      # If no block is given, an `Enumerator` is returned.
      #
      # @overload each_descendant
      #   Yield all nodes.
      # @overload each_descendant(type)
      #   Yield only nodes matching the type.
      #   @param [Symbol] type a node type
      # @overload each_descendant(type_a, type_b, ...)
      #   Yield only nodes matching any of the types.
      #   @param [Symbol] type_a a node type
      #   @param [Symbol] type_b a node type
      # @yieldparam [Node] node each descendant node
      # @return [self] if a block is given
      # @return [Enumerator] if no block is given
      def each_descendant(*types, &block)
        return to_enum(__method__, *types) unless block

        visit_descendants(types, &block)

        self
      end

      # Returns an array of descendant nodes.
      # This is a shorthand for `node.each_descendant.to_a`.
      #
      # @return [Array<Node>] an array of descendant nodes
      def descendants
        each_descendant.to_a
      end

      # Calls the given block for the receiver and each descendant node in
      # depth-first order.
      # If no block is given, an `Enumerator` is returned.
      #
      # This method would be useful when you treat the receiver node as the root
      # of a tree and want to iterate over all nodes in the tree.
      #
      # @overload each_node
      #   Yield all nodes.
      # @overload each_node(type)
      #   Yield only nodes matching the type.
      #   @param [Symbol] type a node type
      # @overload each_node(type_a, type_b, ...)
      #   Yield only nodes matching any of the types.
      #   @param [Symbol] type_a a node type
      #   @param [Symbol] type_b a node type
      # @yieldparam [Node] node each node
      # @return [self] if a block is given
      # @return [Enumerator] if no block is given
      def each_node(*types, &block)
        return to_enum(__method__, *types) unless block

        yield self if types.empty? || type?(*types)

        visit_descendants(types, &block)

        self
      end

      protected

      def visit_descendants(types, &block)
        children.each do |child|
          next unless child.is_a?(::AST::Node)

          yield child if types.empty? || child.type?(*types)
          child.visit_descendants(types, &block)
        end
      end
    end
  end
end
