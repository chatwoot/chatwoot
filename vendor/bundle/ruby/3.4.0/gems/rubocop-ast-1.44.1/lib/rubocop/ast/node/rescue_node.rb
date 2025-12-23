# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `rescue` nodes. This will be used in place of a
    # plain node when the builder constructs the AST, making its methods
    # available to all `rescue` nodes within RuboCop.
    class RescueNode < Node
      # Returns the body of the rescue node.
      #
      # @return [Node, nil] The body of the rescue node.
      def body
        node_parts[0]
      end

      # Returns an array of all the rescue branches in the exception handling statement.
      #
      # @return [Array<ResbodyNode>] an array of `resbody` nodes
      def resbody_branches
        node_parts[1...-1]
      end

      # Returns an array of all the rescue branches in the exception handling statement.
      #
      # @return [Array<Node, nil>] an array of the bodies of the rescue branches
      # and the else (if any). Note that these bodies could be nil.
      def branches
        bodies = resbody_branches.map(&:body)
        bodies.push(else_branch) if else?
        bodies
      end

      # Returns the else branch of the exception handling statement, if any.
      #
      # @return [Node] the else branch node of the exception handling statement
      # @return [nil] if the exception handling statement does not have an else branch.
      def else_branch
        node_parts[-1]
      end

      # Checks whether this exception handling statement has an `else` branch.
      #
      # @return [Boolean] whether the exception handling statement has an `else` branch
      def else?
        loc.else
      end
    end
  end
end
