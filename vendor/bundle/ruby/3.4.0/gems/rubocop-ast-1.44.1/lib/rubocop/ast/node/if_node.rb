# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `if` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `if` nodes within RuboCop.
    class IfNode < Node
      include ConditionalNode
      include ModifierNode

      # Checks whether this node is an `if` statement. (This is not true of
      # ternary operators and `unless` statements.)
      #
      # @return [Boolean] whether the node is an `if` statement
      def if?
        keyword == 'if'
      end

      # Checks whether this node is an `unless` statement. (This is not true
      # of ternary operators and `if` statements.)
      #
      # @return [Boolean] whether the node is an `unless` statement
      def unless?
        keyword == 'unless'
      end

      # Checks whether the `if` node has an `then` clause.
      #
      # @return [Boolean] whether the node has an `then` clause
      def then?
        loc_is?(:begin, 'then')
      end

      # Checks whether the `if` is an `elsif`. Parser handles these by nesting
      # `if` nodes in the `else` branch.
      #
      # @return [Boolean] whether the node is an `elsif`
      def elsif?
        keyword == 'elsif'
      end

      # Checks whether the `if` node has an `else` clause.
      #
      # @note This returns `true` for nodes containing an `elsif` clause.
      #       This is legacy behavior, and many cops rely on it.
      #
      # @return [Boolean] whether the node has an `else` clause
      def else?
        loc?(:else)
      end

      # Checks whether the `if` node is a ternary operator.
      #
      # @return [Boolean] whether the `if` node is a ternary operator
      def ternary?
        loc?(:question)
      end

      # Returns the keyword of the `if` statement as a string. Returns an empty
      # string for ternary operators.
      #
      # @return [String] the keyword of the `if` statement
      def keyword
        ternary? ? '' : loc.keyword.source
      end

      # Returns the inverse keyword of the `if` node as a string. Returns `if`
      # for `unless` nodes and vice versa. Returns an empty string for ternary
      # operators.
      #
      # @return [String] the inverse keyword of the `if` statement
      def inverse_keyword
        case keyword
        when 'if' then 'unless'
        when 'unless' then 'if'
        else
          ''
        end
      end

      # Checks whether the `if` node is in a modifier form, i.e. a condition
      # trailing behind an expression. Only `if` and `unless` nodes without
      # other branches can be modifiers.
      #
      # @return [Boolean] whether the `if` node is a modifier
      def modifier_form?
        (if? || unless?) && super
      end

      # Checks whether the `if` node has nested `if` nodes in any of its
      # branches.
      #
      # @note This performs a shallow search.
      #
      # @return [Boolean] whether the `if` node contains nested conditionals
      def nested_conditional?
        node_parts[1..2].compact.each do |branch|
          branch.each_node(:if) do |nested|
            return true unless nested.elsif?
          end
        end

        false
      end

      # Checks whether the `if` node has at least one `elsif` branch. Returns
      # true if this `if` node itself is an `elsif`.
      #
      # @return [Boolean] whether the `if` node has at least one `elsif` branch
      def elsif_conditional?
        else_branch&.if_type? && else_branch.elsif?
      end

      # Returns the branch of the `if` node that gets evaluated when its
      # condition is truthy.
      #
      # @note This is normalized for `unless` nodes.
      #
      # @return [Node] the truthy branch node of the `if` node
      # @return [nil] if the truthy branch is empty
      def if_branch
        node_parts[1]
      end

      # Returns the branch of the `if` node that gets evaluated when its
      # condition is falsey.
      #
      # @note This is normalized for `unless` nodes.
      #
      # @return [Node] the falsey branch node of the `if` node
      # @return [nil] when there is no else branch
      def else_branch
        node_parts[2]
      end

      # Custom destructuring method. This is used to normalize the branches
      # for `if` and `unless` nodes, to aid comparisons and conversions.
      #
      # @return [Array<Node>] the different parts of the `if` statement
      def node_parts
        if unless?
          condition, false_branch, true_branch = *self
        else
          condition, true_branch, false_branch = *self
        end

        [condition, true_branch, false_branch]
      end

      # Returns an array of all the branches in the conditional statement.
      #
      # @return [Array<Node>] an array of branch nodes
      def branches
        if ternary?
          [if_branch, else_branch]
        elsif !else?
          [if_branch]
        else
          branches = [if_branch]
          other_branches = if elsif_conditional?
                             else_branch.branches
                           else
                             [else_branch]
                           end
          branches.concat(other_branches)
        end
      end

      # @deprecated Use `branches.each`
      def each_branch(&block)
        return branches.to_enum(__method__) unless block

        branches.each(&block)
      end
    end
  end
end
