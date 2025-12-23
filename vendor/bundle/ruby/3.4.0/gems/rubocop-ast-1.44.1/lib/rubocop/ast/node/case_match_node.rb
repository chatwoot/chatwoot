# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `case_match` nodes. This will be used in place of
    # a plain node when the builder constructs the AST, making its methods
    # available to all `case_match` nodes within RuboCop.
    class CaseMatchNode < Node
      include ConditionalNode

      # Returns the keyword of the `case` statement as a string.
      #
      # @return [String] the keyword of the `case` statement
      def keyword
        'case'
      end

      # @deprecated Use `in_pattern_branches.each`
      def each_in_pattern(&block)
        return in_pattern_branches.to_enum(__method__) unless block

        in_pattern_branches.each(&block)

        self
      end

      # Returns an array of all the `in` pattern branches in the `case` statement.
      #
      # @return [Array<InPatternNode>] an array of `in_pattern` nodes
      def in_pattern_branches
        node_parts[1...-1]
      end

      # Returns an array of all the when branches in the `case` statement.
      #
      # @return [Array<Node, nil>] an array of the bodies of the `in` branches
      # and the `else` (if any). Note that these bodies could be nil.
      def branches
        bodies = in_pattern_branches.map(&:body)
        if else?
          # `empty-else` node sets nil because it has no body.
          else_branch.empty_else_type? ? bodies.push(nil) : bodies.push(else_branch)
        end
        bodies
      end

      # Returns the else branch of the `case` statement, if any.
      #
      # @return [Node] the else branch node of the `case` statement
      # @return [EmptyElse] the empty else branch node of the `case` statement
      # @return [nil] if the case statement does not have an else branch.
      def else_branch
        node_parts[-1]
      end

      # Checks whether this case statement has an `else` branch.
      #
      # @return [Boolean] whether the `case` statement has an `else` branch
      def else?
        !loc.else.nil?
      end
    end
  end
end
