# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the indentation of the right hand side operand in binary operations that
      # span more than one line.
      #
      # The `aligned` style checks that operators are aligned if they are part of an `if` or `while`
      # condition, an explicit `return` statement, etc. In other contexts, the second operand should
      # be indented regardless of enforced style.
      #
      # @example EnforcedStyle: aligned (default)
      #   # bad
      #   if a +
      #       b
      #     something &&
      #     something_else
      #   end
      #
      #   # good
      #   if a +
      #      b
      #     something &&
      #       something_else
      #   end
      #
      # @example EnforcedStyle: indented
      #   # bad
      #   if a +
      #      b
      #     something &&
      #     something_else
      #   end
      #
      #   # good
      #   if a +
      #       b
      #     something &&
      #       something_else
      #   end
      #
      class MultilineOperationIndentation < Base
        include ConfigurableEnforcedStyle
        include Alignment
        include MultilineExpressionIndentation
        extend AutoCorrector

        def on_and(node)
          check_and_or(node)
        end

        def on_or(node)
          check_and_or(node)
        end

        def validate_config
          return unless style == :aligned && cop_config['IndentationWidth']

          raise ValidationError, 'The `Layout/MultilineOperationIndentation` ' \
                                 'cop only accepts an `IndentationWidth` ' \
                                 'configuration parameter when ' \
                                 '`EnforcedStyle` is `indented`.'
        end

        private

        def autocorrect(corrector, node)
          AlignmentCorrector.correct(corrector, processed_source, node, @column_delta)
        end

        def relevant_node?(node)
          return false if node.send_type? && node.unary_operation?

          !node.loc.dot # Don't check method calls with dot operator.
        end

        def check_and_or(node)
          range = offending_range(node, node.lhs, node.rhs.source_range, style)
          check(range, node, node.lhs, node.rhs.source_range)
        end

        def offending_range(node, lhs, rhs, given_style)
          return false unless begins_its_line?(rhs)
          return false if not_for_this_cop?(node)

          correct_column = if should_align?(node, rhs, given_style)
                             node.loc.column
                           else
                             indentation(lhs) + correct_indentation(node)
                           end
          @column_delta = correct_column - rhs.column
          rhs if @column_delta.nonzero?
        end

        def should_align?(node, rhs, given_style)
          assignment_node = part_of_assignment_rhs(node, rhs)
          if assignment_node
            assignment_rhs = CheckAssignment.extract_rhs(assignment_node)
            return true if begins_its_line?(assignment_rhs.source_range)
          end

          given_style == :aligned &&
            (kw_node_with_special_indentation(node) ||
             assignment_node ||
             argument_in_method_call(node, :with_or_without_parentheses))
        end

        def message(node, lhs, rhs)
          what = operation_description(node, rhs)
          if should_align?(node, rhs, style)
            "Align the operands of #{what} spanning multiple lines."
          else
            used_indentation = rhs.column - indentation(lhs)
            "Use #{correct_indentation(node)} (not #{used_indentation}) " \
              "spaces for indenting #{what} spanning multiple lines."
          end
        end

        def right_hand_side(send_node)
          send_node.first_argument&.source_range
        end
      end
    end
  end
end
