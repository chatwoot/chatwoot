# frozen_string_literal: true

module RuboCop
  module AST
    # Common functionality for nodes that are binary operations:
    # `or`, `and` ...
    module BinaryOperatorNode
      # Returns the left hand side node of the binary operation.
      #
      # @return [Node] the left hand side of the binary operation
      def lhs
        node_parts[0]
      end

      # Returns the right hand side node of the binary operation.
      #
      # @return [Node] the right hand side of the binary operation
      def rhs
        node_parts[1]
      end

      # Returns all of the conditions, including nested conditions,
      # of the binary operation.
      #
      # @return [Array<Node>] the left and right hand side of the binary
      # operation and the let and right hand side of any nested binary
      # operators
      def conditions
        lhs, rhs = *self
        lhs = lhs.children.first if lhs.begin_type?
        rhs = rhs.children.first if rhs.begin_type?

        [lhs, rhs].each_with_object([]) do |side, collection|
          if side.operator_keyword?
            collection.concat(side.conditions)
          else
            collection << side
          end
        end
      end
    end
  end
end
