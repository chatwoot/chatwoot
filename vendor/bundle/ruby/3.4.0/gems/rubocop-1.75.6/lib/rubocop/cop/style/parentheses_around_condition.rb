# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for the presence of superfluous parentheses around the
      # condition of if/unless/while/until.
      #
      # `AllowSafeAssignment` option for safe assignment.
      # By safe assignment we mean putting parentheses around
      # an assignment to indicate "I know I'm using an assignment
      # as a condition. It's not a mistake."
      #
      # @example
      #   # bad
      #   x += 1 while (x < 10)
      #   foo unless (bar || baz)
      #
      #   if (x > 10)
      #   elsif (x < 3)
      #   end
      #
      #   # good
      #   x += 1 while x < 10
      #   foo unless bar || baz
      #
      #   if x > 10
      #   elsif x < 3
      #   end
      #
      # @example AllowSafeAssignment: true (default)
      #   # good
      #   foo unless (bar = baz)
      #
      # @example AllowSafeAssignment: false
      #   # bad
      #   foo unless (bar = baz)
      #
      # @example AllowInMultilineConditions: false (default)
      #   # bad
      #   if (x > 10 &&
      #      y > 10)
      #   end
      #
      #   # good
      #    if x > 10 &&
      #       y > 10
      #    end
      #
      # @example AllowInMultilineConditions: true
      #   # good
      #   if (x > 10 &&
      #      y > 10)
      #   end
      #
      class ParenthesesAroundCondition < Base
        include SafeAssignment
        include Parentheses
        include RangeHelp
        extend AutoCorrector

        def on_if(node)
          return if node.ternary?

          process_control_op(node)
        end

        def on_while(node)
          process_control_op(node)
        end
        alias on_until on_while

        private

        # @!method control_op_condition(node)
        def_node_matcher :control_op_condition, <<~PATTERN
          (begin $_ $...)
        PATTERN

        def process_control_op(node)
          cond = node.condition

          control_op_condition(cond) do |first_child, rest_children|
            return if require_parentheses?(node, first_child)
            return if semicolon_separated_expressions?(first_child, rest_children)
            return if modifier_op?(first_child)
            return if parens_allowed?(cond)

            message = message(cond)
            add_offense(cond, message: message) do |corrector|
              ParenthesesCorrector.correct(corrector, cond)
            end
          end
        end

        def require_parentheses?(node, condition_body)
          return false unless node.type?(:while, :until)
          return false unless condition_body.any_block_type?

          condition_body.send_node.block_literal? && condition_body.keywords?
        end

        def semicolon_separated_expressions?(first_exp, rest_exps)
          return false unless (second_exp = rest_exps.first)

          range = range_between(first_exp.source_range.end_pos, second_exp.source_range.begin_pos)

          range.source.include?(';')
        end

        def modifier_op?(node)
          return false if node.if_type? && node.ternary?
          return true if node.rescue_type?

          node.basic_conditional? && node.modifier_form?
        end

        def message(node)
          kw = node.parent.keyword
          article = kw == 'while' ? 'a' : 'an'
          "Don't use parentheses around the condition of #{article} `#{kw}`."
        end

        def parens_allowed?(node)
          parens_required?(node) ||
            (safe_assignment?(node) && safe_assignment_allowed?) ||
            (node.multiline? && allow_multiline_conditions?)
        end

        def allow_multiline_conditions?
          cop_config['AllowInMultilineConditions']
        end
      end
    end
  end
end
