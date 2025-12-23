# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for places where conditional branch makes redundant self-assignment.
      #
      # It only detects local variable because it may replace state of instance variable,
      # class variable, and global variable that have state across methods with `nil`.
      #
      # @example
      #
      #   # bad
      #   foo = condition ? bar : foo
      #
      #   # good
      #   foo = bar if condition
      #
      #   # bad
      #   foo = condition ? foo : bar
      #
      #   # good
      #   foo = bar unless condition
      #
      class RedundantSelfAssignmentBranch < Base
        extend AutoCorrector

        MSG = 'Remove the self-assignment branch.'

        # @!method bad_method?(node)
        def_node_matcher :bad_method?, <<~PATTERN
          (send nil? :bad_method ...)
        PATTERN

        def on_lvasgn(node)
          expression = node.expression

          return unless use_if_and_else_branch?(expression)

          if_branch = expression.if_branch
          else_branch = expression.else_branch
          return if inconvertible_to_modifier?(if_branch, else_branch)

          if self_assign?(node.name, if_branch)
            register_offense(expression, if_branch, else_branch, 'unless')
          elsif self_assign?(node.name, else_branch)
            register_offense(expression, else_branch, if_branch, 'if')
          end
        end

        private

        def use_if_and_else_branch?(expression)
          return false unless expression&.if_type?

          !expression.ternary? || !expression.else?
        end

        def inconvertible_to_modifier?(if_branch, else_branch)
          multiple_statements?(if_branch) || multiple_statements?(else_branch) ||
            (else_branch.respond_to?(:elsif?) && else_branch.elsif?)
        end

        def multiple_statements?(branch)
          return false unless branch&.begin_type?

          !branch.children.empty?
        end

        def self_assign?(variable, branch)
          variable.to_s == branch&.source
        end

        def register_offense(if_node, offense_branch, opposite_branch, keyword)
          add_offense(offense_branch) do |corrector|
            assignment_value = opposite_branch ? opposite_branch.source : 'nil'
            replacement = "#{assignment_value} #{keyword} #{if_node.condition.source}"
            if opposite_branch.respond_to?(:heredoc?) && opposite_branch.heredoc?
              replacement += opposite_branch.loc.heredoc_end.with(
                begin_pos: opposite_branch.source_range.end_pos
              ).source
            end

            corrector.replace(if_node, replacement)
          end
        end
      end
    end
  end
end
