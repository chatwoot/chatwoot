# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the indentation of the first line of the
      # right-hand-side of a multi-line assignment.
      #
      # The indentation of the remaining lines can be corrected with
      # other cops such as `Layout/IndentationConsistency` and `Layout/EndAlignment`.
      #
      # @example
      #   # bad
      #   value =
      #   if foo
      #     'bar'
      #   end
      #
      #   # good
      #   value =
      #     if foo
      #       'bar'
      #     end
      #
      class AssignmentIndentation < Base
        include CheckAssignment
        include Alignment
        extend AutoCorrector

        MSG = 'Indent the first line of the right-hand-side of a multi-line assignment.'

        private

        def check_assignment(node, rhs)
          return unless rhs
          return unless node.loc.operator
          return if same_line?(node.loc.operator, rhs)

          base = display_column(leftmost_multiple_assignment(node).source_range)
          check_alignment([rhs], base + configured_indentation_width)
        end

        def autocorrect(corrector, node)
          AlignmentCorrector.correct(corrector, processed_source, node, column_delta)
        end

        def leftmost_multiple_assignment(node)
          return node unless same_line?(node, node.parent) && node.parent.assignment?

          leftmost_multiple_assignment(node.parent)

          node.parent
        end
      end
    end
  end
end
