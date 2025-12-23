# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for expressions where there is a call to a predicate
      # method with at least one argument, where no parentheses are used around
      # the parameter list, and a boolean operator, && or ||, is used in the
      # last argument.
      #
      # The idea behind warning for these constructs is that the user might
      # be under the impression that the return value from the method call is
      # an operand of &&/||.
      #
      # @example
      #
      #   # bad
      #   if day.is? :tuesday && month == :jan
      #     # ...
      #   end
      #
      #   # good
      #   if day.is?(:tuesday) && month == :jan
      #     # ...
      #   end
      class RequireParentheses < Base
        include RangeHelp

        MSG = 'Use parentheses in the method call to avoid confusion about precedence.'

        def on_send(node)
          return if !node.arguments? || node.parenthesized?

          if node.first_argument.if_type? && node.first_argument.ternary?
            check_ternary(node.first_argument, node)
          elsif node.predicate_method?
            check_predicate(node.last_argument, node)
          end
        end
        alias on_csend on_send

        private

        def check_ternary(ternary, node)
          if node.method?(:[]) || node.assignment_method? || !ternary.condition.operator_keyword?
            return
          end

          range = range_between(node.source_range.begin_pos, ternary.condition.source_range.end_pos)

          add_offense(range)
        end

        def check_predicate(predicate, node)
          return unless predicate.operator_keyword?

          add_offense(node)
        end
      end
    end
  end
end
