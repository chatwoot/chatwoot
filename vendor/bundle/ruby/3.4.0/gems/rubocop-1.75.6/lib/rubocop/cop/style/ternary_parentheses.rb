# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for the presence of parentheses around ternary
      # conditions. It is configurable to enforce inclusion or omission of
      # parentheses using `EnforcedStyle`. Omission is only enforced when
      # removing the parentheses won't cause a different behavior.
      #
      # `AllowSafeAssignment` option for safe assignment.
      # By safe assignment we mean putting parentheses around
      # an assignment to indicate "I know I'm using an assignment
      # as a condition. It's not a mistake."
      #
      # @example EnforcedStyle: require_no_parentheses (default)
      #   # bad
      #   foo = (bar?) ? a : b
      #   foo = (bar.baz?) ? a : b
      #   foo = (bar && baz) ? a : b
      #
      #   # good
      #   foo = bar? ? a : b
      #   foo = bar.baz? ? a : b
      #   foo = bar && baz ? a : b
      #
      # @example EnforcedStyle: require_parentheses
      #   # bad
      #   foo = bar? ? a : b
      #   foo = bar.baz? ? a : b
      #   foo = bar && baz ? a : b
      #
      #   # good
      #   foo = (bar?) ? a : b
      #   foo = (bar.baz?) ? a : b
      #   foo = (bar && baz) ? a : b
      #
      # @example EnforcedStyle: require_parentheses_when_complex
      #   # bad
      #   foo = (bar?) ? a : b
      #   foo = (bar.baz?) ? a : b
      #   foo = bar && baz ? a : b
      #
      #   # good
      #   foo = bar? ? a : b
      #   foo = bar.baz? ? a : b
      #   foo = (bar && baz) ? a : b
      #
      # @example AllowSafeAssignment: true (default)
      #   # good
      #   foo = (bar = baz) ? a : b
      #
      # @example AllowSafeAssignment: false
      #   # bad
      #   foo = (bar = baz) ? a : b
      #
      class TernaryParentheses < Base
        include SafeAssignment
        include ConfigurableEnforcedStyle
        include SurroundingSpace
        extend AutoCorrector

        VARIABLE_TYPES = AST::Node::VARIABLES
        NON_COMPLEX_TYPES = [*VARIABLE_TYPES, :const, :defined?, :yield].freeze

        MSG = '%<command>s parentheses for ternary conditions.'
        MSG_COMPLEX = '%<command>s parentheses for ternary expressions with complex conditions.'

        def on_if(node)
          condition = node.condition

          return if only_closing_parenthesis_is_last_line?(condition)
          return if condition_as_parenthesized_one_line_pattern_matching?(condition)
          return unless node.ternary? && offense?(node)

          message = message(node)

          add_offense(node, message: message) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def only_closing_parenthesis_is_last_line?(condition)
          condition.source.split("\n").last == ')'
        end

        def condition_as_parenthesized_one_line_pattern_matching?(condition)
          return false unless condition.parenthesized_call?
          return false unless (first_child = condition.children.first)

          if target_ruby_version >= 3.0
            first_child.match_pattern_p_type?
          else
            first_child.match_pattern_type? # For Ruby 2.7's one line pattern matching AST.
          end
        end

        def autocorrect(corrector, node)
          condition = node.condition

          return nil if parenthesized?(condition) &&
                        (safe_assignment?(condition) || unsafe_autocorrect?(condition))

          if parenthesized?(condition)
            correct_parenthesized(corrector, condition)
          else
            correct_unparenthesized(corrector, condition)
          end
        end

        def offense?(node)
          condition = node.condition

          if safe_assignment?(condition)
            !safe_assignment_allowed?
          else
            parens = parenthesized?(condition)
            case style
            when :require_parentheses_when_complex
              complex_condition?(condition) ? !parens : parens
            else
              require_parentheses? ? !parens : parens
            end
          end
        end

        # If the condition is parenthesized we recurse and check for any
        # complex expressions within it.
        def complex_condition?(condition)
          if condition.begin_type?
            condition.to_a.any? { |x| complex_condition?(x) }
          else
            !non_complex_expression?(condition)
          end
        end

        # Anything that is not a variable, constant, or method/.method call
        # will be counted as a complex expression.
        def non_complex_expression?(condition)
          NON_COMPLEX_TYPES.include?(condition.type) || non_complex_send?(condition)
        end

        def non_complex_send?(node)
          return false unless node.call_type?

          !node.operator_method? || node.method?(:[])
        end

        def message(node)
          if require_parentheses_when_complex?
            command = parenthesized?(node.condition) ? 'Only use' : 'Use'
            format(MSG_COMPLEX, command: command)
          else
            command = require_parentheses? ? 'Use' : 'Omit'
            format(MSG, command: command)
          end
        end

        def require_parentheses?
          style == :require_parentheses
        end

        def require_parentheses_when_complex?
          style == :require_parentheses_when_complex
        end

        def parenthesized?(node)
          node.begin_type?
        end

        def unsafe_autocorrect?(condition)
          condition.children.any? { |child| below_ternary_precedence?(child) }
        end

        def unparenthesized_method_call?(child)
          /^[a-z]/i.match?(method_name(child)) && !child.parenthesized?
        end

        def below_ternary_precedence?(child)
          # Handle English "or", e.g. 'foo or bar ? a : b'
          (child.or_type? && child.semantic_operator?) ||
            # Handle English "and", e.g. 'foo and bar ? a : b'
            (child.and_type? && child.semantic_operator?) ||
            # Handle English "not", e.g. 'not foo ? a : b'
            (child.send_type? && child.prefix_not?)
        end

        # @!method method_name(node)
        def_node_matcher :method_name, <<~PATTERN
          {($:defined? _ ...)
           (call {_ nil?} $_ _ ...)}
        PATTERN

        def correct_parenthesized(corrector, condition)
          corrector.remove(condition.loc.begin)
          corrector.remove(condition.loc.end)

          # Ruby allows no space between the question mark and parentheses.
          # If we remove the parentheses, we need to add a space or we'll
          # generate invalid code.
          corrector.insert_after(condition.loc.end, ' ') unless whitespace_after?(condition)

          if (send_node = condition.child_nodes.last) && node_args_need_parens?(send_node)
            parenthesize_condition_arguments(corrector, send_node)
          end
        end

        def correct_unparenthesized(corrector, condition)
          corrector.wrap(condition, '(', ')')
        end

        def parenthesize_condition_arguments(corrector, send_node)
          range_start = send_node.defined_type? ? send_node.loc.keyword : send_node.loc.selector
          opening_range = range_start.end.join(send_node.first_argument.source_range.begin)

          corrector.replace(opening_range, '(')
          corrector.insert_after(send_node.last_argument, ')')
        end

        def whitespace_after?(node)
          last_token = processed_source.last_token_of(node)
          last_token.space_after?
        end

        def node_args_need_parens?(send_node)
          return false unless node_with_args?(send_node)
          return false if send_node.arguments.none? || send_node.parenthesized?

          send_node.dot? || send_node.safe_navigation? || unparenthesized_method_call?(send_node)
        end

        def node_with_args?(node)
          node.type?(:call, :defined?)
        end
      end
    end
  end
end
