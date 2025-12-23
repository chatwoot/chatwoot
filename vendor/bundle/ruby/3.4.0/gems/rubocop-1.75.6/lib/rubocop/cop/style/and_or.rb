# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of `and` and `or`, and suggests using `&&` and
      # `||` instead. It can be configured to check only in conditions or in
      # all contexts.
      #
      # @safety
      #   Autocorrection is unsafe because there is a different operator precedence
      #   between logical operators (`&&` and `||`) and semantic operators (`and` and `or`),
      #   and that might change the behavior.
      #
      # @example EnforcedStyle: conditionals (default)
      #   # bad
      #   if foo and bar
      #   end
      #
      #   # good
      #   foo.save && return
      #
      #   # good
      #   foo.save and return
      #
      #   # good
      #   if foo && bar
      #   end
      #
      # @example EnforcedStyle: always
      #   # bad
      #   foo.save and return
      #
      #   # bad
      #   if foo and bar
      #   end
      #
      #   # good
      #   foo.save && return
      #
      #   # good
      #   if foo && bar
      #   end
      class AndOr < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead of `%<current>s`.'

        def on_and(node)
          process_logical_operator(node) if style == :always
        end
        alias on_or on_and

        def on_if(node)
          on_conditionals(node) if style == :conditionals
        end
        alias on_while      on_if
        alias on_while_post on_if
        alias on_until      on_if
        alias on_until_post on_if

        private

        def process_logical_operator(node)
          return if node.logical_operator?

          message = message(node)
          add_offense(node.loc.operator, message: message) do |corrector|
            node.each_child_node do |expr|
              if expr.send_type?
                correct_send(expr, corrector)
              elsif expr.return_type? || expr.assignment?
                correct_other(expr, corrector)
              end
            end

            corrector.replace(node.loc.operator, node.alternate_operator)

            keep_operator_precedence(corrector, node)
          end
        end

        def on_conditionals(node)
          node.condition.each_node(*AST::Node::OPERATOR_KEYWORDS) do |operator|
            process_logical_operator(operator)
          end
        end

        def message(node)
          format(MSG, prefer: node.alternate_operator, current: node.operator)
        end

        def correct_send(node, corrector)
          return correct_not(node, node.receiver, corrector) if node.method?(:!)
          return correct_setter(node, corrector) if node.setter_method?
          return correct_other(node, corrector) if node.comparison_method?

          return unless correctable_send?(node)

          whitespace_before_arg_range = whitespace_before_arg(node)
          corrector.remove(whitespace_before_arg_range)
          corrector.insert_before(whitespace_before_arg_range, '(')
          corrector.insert_after(node.last_argument, ')')
        end

        def correct_setter(node, corrector)
          corrector.insert_before(node.receiver, '(')
          corrector.insert_after(node.last_argument, ')')
        end

        # ! is a special case:
        # 'x and !obj.method arg' can be autocorrected if we
        # recurse down a level and add parens to 'obj.method arg'
        # however, 'not x' also parses as (send x :!)
        def correct_not(node, receiver, corrector)
          if node.prefix_bang?
            return unless receiver.send_type?

            correct_send(receiver, corrector)
          elsif node.prefix_not?
            correct_other(node, corrector)
          else
            raise 'unrecognized unary negation operator'
          end
        end

        def correct_other(node, corrector)
          return if node.parenthesized_call?

          corrector.wrap(node, '(', ')')
        end

        def keep_operator_precedence(corrector, node)
          if node.or_type? && node.parent&.and_type?
            corrector.wrap(node, '(', ')')
          elsif node.and_type? && node.rhs.or_type?
            corrector.wrap(node.rhs, '(', ')')
          end
        end

        def correctable_send?(node)
          !node.parenthesized? && node.arguments? && !node.method?(:[])
        end

        def whitespace_before_arg(node)
          begin_paren = node.loc.selector.end_pos
          end_paren = begin_paren
          # Increment position of parenthesis, unless message is a predicate
          # method followed by a non-whitespace char (e.g. is_a?String).
          end_paren += 1 unless /\?\S/.match?(node.source)
          range_between(begin_paren, end_paren)
        end
      end
    end
  end
end
