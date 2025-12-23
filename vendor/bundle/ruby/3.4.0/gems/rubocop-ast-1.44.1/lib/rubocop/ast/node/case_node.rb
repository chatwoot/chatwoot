# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `case` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `case` nodes within RuboCop.
    class CaseNode < Node
      include ConditionalNode

      # Returns the keyword of the `case` statement as a string.
      #
      # @return [String] the keyword of the `case` statement
      def keyword
        'case'
      end

      # @deprecated Use `when_branches.each`
      def each_when(&block)
        return when_branches.to_enum(__method__) unless block

        when_branches.each(&block)

        self
      end

      # Returns an array of all the when branches in the `case` statement.
      #
      # @return [Array<WhenNode>] an array of `when` nodes
      def when_branches
        node_parts[1...-1]
      end

      # Returns an array of all the when branches in the `case` statement.
      #
      # @return [Array<Node, nil>] an array of the bodies of the when branches
      # and the else (if any). Note that these bodies could be nil.
      def branches
        bodies = when_branches.map(&:body)
        bodies.push(else_branch) if else?
        bodies
      end

      # Returns the else branch of the `case` statement, if any.
      #
      # @return [Node] the else branch node of the `case` statement
      # @return [nil] if the case statement does not have an else branch.
      def else_branch
        node_parts[-1]
      end

      # Checks whether this case statement has an `else` branch.
      #
      # @return [Boolean] whether the `case` statement has an `else` branch
      def else?
        loc.else
      end
    end
  end
end
