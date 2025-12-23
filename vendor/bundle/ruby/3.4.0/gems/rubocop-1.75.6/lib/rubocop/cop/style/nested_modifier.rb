# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for nested use of if, unless, while and until in their
      # modifier form.
      #
      # @example
      #
      #   # bad
      #   something if a if b
      #
      #   # good
      #   something if b && a
      class NestedModifier < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Avoid using nested modifiers.'

        def on_while(node)
          check(node)
        end
        alias on_until on_while
        alias on_if on_while

        private

        def check(node)
          return if part_of_ignored_node?(node)
          return unless modifier?(node) && modifier?(node.parent)

          add_offense(node.loc.keyword) { |corrector| autocorrect(corrector, node) }
          ignore_node(node)
        end

        def modifier?(node)
          node&.basic_conditional? && node.modifier_form?
        end

        def autocorrect(corrector, node)
          return unless node.if_type? && node.parent.if_type?

          range = range_between(node.loc.keyword.begin_pos,
                                node.parent.condition.source_range.end_pos)

          corrector.replace(range, new_expression(node))
        end

        def new_expression(inner_node)
          outer_node = inner_node.parent

          operator = replacement_operator(outer_node.keyword)
          lh_operand = left_hand_operand(outer_node, operator)
          rh_operand = right_hand_operand(inner_node, outer_node.keyword)

          "#{outer_node.keyword} #{lh_operand} #{operator} #{rh_operand}"
        end

        def replacement_operator(keyword)
          keyword == 'if' ? '&&' : '||'
        end

        def left_hand_operand(node, operator)
          expr = node.condition.source
          expr = "(#{expr})" if node.condition.or_type? && operator == '&&'
          expr
        end

        def right_hand_operand(node, left_hand_keyword)
          condition = node.condition

          expr = if condition.send_type? && !condition.arguments.empty? &&
                    !condition.operator_method?
                   add_parentheses_to_method_arguments(condition)
                 else
                   condition.source
                 end
          expr = "(#{expr})" if requires_parens?(condition)
          expr = "!#{expr}" unless left_hand_keyword == node.keyword
          expr
        end

        def add_parentheses_to_method_arguments(send_node)
          expr = +''
          expr << "#{send_node.receiver.source}." if send_node.receiver
          expr << send_node.method_name.to_s
          expr << "(#{send_node.arguments.map(&:source).join(', ')})"

          expr
        end

        def requires_parens?(node)
          node.or_type? || !(RuboCop::AST::Node::COMPARISON_OPERATORS & node.children).empty?
        end
      end
    end
  end
end
