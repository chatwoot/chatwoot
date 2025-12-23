# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `resbody` nodes. This will be used in place of a
    # plain node when the builder constructs the AST, making its methods
    # available to all `resbody` nodes within RuboCop.
    class ResbodyNode < Node
      # Returns the body of the `rescue` clause.
      #
      # @return [Node, nil] The body of the `resbody`.
      def body
        node_parts[2]
      end

      # Returns an array of all the exceptions in the `rescue` clause.
      #
      # @return [Array<Node>] an array of exception nodes
      def exceptions
        exceptions_node = node_parts[0]
        if exceptions_node.nil?
          []
        elsif exceptions_node.array_type?
          exceptions_node.values
        else
          [exceptions_node]
        end
      end

      # Returns the exception variable of the `rescue` clause.
      #
      # @return [Node, nil] The exception variable of the `resbody`.
      def exception_variable
        node_parts[1]
      end

      # Returns the index of the `resbody` branch within the exception handling statement.
      #
      # @return [Integer] the index of the `resbody` branch
      def branch_index
        parent.resbody_branches.index(self)
      end
    end
  end
end
