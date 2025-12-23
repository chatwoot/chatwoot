# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use of shorthand-style swapping of 2 variables.
      #
      # @safety
      #   Autocorrection is unsafe, because the temporary variable used to
      #   swap variables will be removed, but may be referred to elsewhere.
      #
      # @example
      #   # bad
      #   tmp = x
      #   x = y
      #   y = tmp
      #
      #   # good
      #   x, y = y, x
      #
      class SwapValues < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Replace this and assignments at lines %<x_line>d ' \
              'and %<y_line>d with `%<replacement>s`.'

        SIMPLE_ASSIGNMENT_TYPES = %i[lvasgn ivasgn cvasgn gvasgn casgn].to_set.freeze

        def on_asgn(node)
          return if allowed_assignment?(node)

          tmp_assign = node
          x_assign, y_assign = *node.right_siblings.take(2)
          return unless x_assign && y_assign && swapping_values?(tmp_assign, x_assign, y_assign)

          add_offense(node, message: message(x_assign, y_assign)) do |corrector|
            range = correction_range(tmp_assign, y_assign)
            corrector.replace(range, replacement(x_assign))
          end
        end

        SIMPLE_ASSIGNMENT_TYPES.each { |asgn_type| alias_method :"on_#{asgn_type}", :on_asgn }

        private

        def allowed_assignment?(node)
          node.parent&.mlhs_type? || node.parent&.shorthand_asgn?
        end

        def swapping_values?(tmp_assign, x_assign, y_assign)
          simple_assignment?(tmp_assign) &&
            simple_assignment?(x_assign) &&
            simple_assignment?(y_assign) &&
            lhs(x_assign) == rhs(tmp_assign) &&
            lhs(y_assign) == rhs(x_assign) &&
            rhs(y_assign) == lhs(tmp_assign)
        end

        def simple_assignment?(node)
          return false unless node.respond_to?(:type)

          SIMPLE_ASSIGNMENT_TYPES.include?(node.type)
        end

        def message(x_assign, y_assign)
          format(
            MSG,
            x_line: x_assign.first_line,
            y_line: y_assign.first_line,
            replacement: replacement(x_assign)
          )
        end

        def replacement(x_assign)
          x = lhs(x_assign)
          y = rhs(x_assign)
          "#{x}, #{y} = #{y}, #{x}"
        end

        def lhs(node)
          if node.casgn_type?
            "#{'::' if node.absolute?}#{node.const_name}"
          else
            node.name.to_s
          end
        end

        def rhs(node)
          node.expression.source
        end

        def correction_range(tmp_assign, y_assign)
          range_by_whole_lines(
            range_between(tmp_assign.source_range.begin_pos, y_assign.source_range.end_pos)
          )
        end
      end
    end
  end
end
