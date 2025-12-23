# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Check to make sure that if safe navigation is used in an `&&` or `||` condition,
      # consistent and appropriate safe navigation, without excess or deficiency,
      # is used for all method calls on the same object.
      #
      # @example
      #   # bad
      #   foo&.bar && foo&.baz
      #
      #   # good
      #   foo&.bar && foo.baz
      #
      #   # bad
      #   foo.bar && foo&.baz
      #
      #   # good
      #   foo.bar && foo.baz
      #
      #   # bad
      #   foo&.bar || foo.baz
      #
      #   # good
      #   foo&.bar || foo&.baz
      #
      #   # bad
      #   foo.bar || foo&.baz
      #
      #   # good
      #   foo.bar || foo.baz
      #
      #   # bad
      #   foo&.bar && (foobar.baz || foo&.baz)
      #
      #   # good
      #   foo&.bar && (foobar.baz || foo.baz)
      #
      class SafeNavigationConsistency < Base
        include NilMethods
        extend AutoCorrector

        USE_DOT_MSG = 'Use `.` instead of unnecessary `&.`.'
        USE_SAFE_NAVIGATION_MSG = 'Use `&.` for consistency with safe navigation.'

        def on_and(node)
          all_operands = collect_operands(node, [])
          operand_groups = all_operands.group_by { |operand| receiver_name_as_key(operand, +'') }

          operand_groups.each_value do |grouped_operands|
            next unless (dot_op, begin_of_rest_operands = find_consistent_parts(grouped_operands))

            rest_operands = grouped_operands[begin_of_rest_operands..]
            rest_operands.each do |operand|
              next if already_appropriate_call?(operand, dot_op)

              register_offense(operand, dot_op)
            end
          end
        end
        alias on_or on_and

        private

        def collect_operands(node, operand_nodes)
          operand_nodes(node.lhs, operand_nodes)
          operand_nodes(node.rhs, operand_nodes)

          operand_nodes
        end

        def receiver_name_as_key(method, fully_receivers)
          if method.parent.call_type?
            receiver(method.parent, fully_receivers)
          else
            fully_receivers << method.receiver&.source.to_s
          end
        end

        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def find_consistent_parts(grouped_operands)
          csend_in_and, csend_in_or, send_in_and, send_in_or = most_left_indices(grouped_operands)

          return if csend_in_and && csend_in_or && csend_in_and < csend_in_or

          if csend_in_and
            ['.', (send_in_and ? [send_in_and, csend_in_and].min : csend_in_and) + 1]
          elsif send_in_or && csend_in_or
            send_in_or < csend_in_or ? ['.', send_in_or + 1] : ['&.', csend_in_or + 1]
          elsif send_in_and && csend_in_or && send_in_and < csend_in_or
            ['.', csend_in_or]
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def already_appropriate_call?(operand, dot_op)
          return true if operand.safe_navigation? && dot_op == '&.'

          (operand.dot? || operand.operator_method?) && dot_op == '.'
        end

        def register_offense(operand, dot_operator)
          offense_range = operand.operator_method? ? operand : operand.loc.dot
          message = dot_operator == '.' ? USE_DOT_MSG : USE_SAFE_NAVIGATION_MSG

          add_offense(offense_range, message: message) do |corrector|
            next if operand.operator_method?

            corrector.replace(operand.loc.dot, dot_operator)
          end
        end

        def operand_nodes(operand, operand_nodes)
          if operand.operator_keyword?
            collect_operands(operand, operand_nodes)
          elsif operand.call_type?
            operand_nodes << operand
          end
        end

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def most_left_indices(grouped_operands)
          indices = { csend_in_and: nil, csend_in_or: nil, send_in_and: nil, send_in_or: nil }

          grouped_operands.each_with_index do |operand, index|
            indices[:csend_in_and] ||= index if operand_in_and?(operand) && operand.csend_type?
            indices[:csend_in_or] ||= index if operand_in_or?(operand) && operand.csend_type?
            indices[:send_in_and] ||= index if operand_in_and?(operand) && !nilable?(operand)
            indices[:send_in_or] ||= index if operand_in_or?(operand) && !nilable?(operand)
          end

          indices.values
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def operand_in_and?(node)
          return true if node.parent.and_type?

          parent = node.parent.parent while node.parent.begin_type?

          parent&.and_type?
        end

        def operand_in_or?(node)
          return true if node.parent.or_type?

          parent = node.parent.parent while node.parent.begin_type?

          parent&.or_type?
        end

        def nilable?(node)
          node.csend_type? || nil_methods.include?(node.method_name)
        end
      end
    end
  end
end
