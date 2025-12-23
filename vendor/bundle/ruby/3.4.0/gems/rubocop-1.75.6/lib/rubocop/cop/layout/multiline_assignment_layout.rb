# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks whether the multiline assignments have a newline
      # after the assignment operator.
      #
      # @example EnforcedStyle: new_line (default)
      #   # bad
      #   foo = if expression
      #     'bar'
      #   end
      #
      #   # good
      #   foo =
      #     if expression
      #       'bar'
      #     end
      #
      #   # good
      #   foo =
      #     begin
      #       compute
      #     rescue => e
      #       nil
      #     end
      #
      # @example EnforcedStyle: same_line
      #   # good
      #   foo = if expression
      #     'bar'
      #   end
      #
      # @example SupportedTypes: ['block', 'case', 'class', 'if', 'kwbegin', 'module'] (default)
      #   # good
      #   foo =
      #     if expression
      #       'bar'
      #     end
      #
      #   # good
      #   foo =
      #     [1].map do |i|
      #       i + 1
      #     end
      #
      # @example SupportedTypes: ['block']
      #   # good
      #   foo = if expression
      #     'bar'
      #   end
      #
      #   # good
      #   foo =
      #     [1].map do |i|
      #       'bar' * i
      #     end
      #
      class MultilineAssignmentLayout < Base
        include CheckAssignment
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        NEW_LINE_OFFENSE = 'Right hand side of multi-line assignment is on ' \
                           'the same line as the assignment operator `=`.'

        SAME_LINE_OFFENSE = 'Right hand side of multi-line assignment is not ' \
                            'on the same line as the assignment operator `=`.'

        def check_assignment(node, rhs)
          return if node.send_type? && node.loc.operator&.source != '='
          return unless rhs
          return unless supported_types.include?(rhs.type)
          return if rhs.single_line?

          check_by_enforced_style(node, rhs)
        end

        def check_by_enforced_style(node, rhs)
          case style
          when :new_line
            check_new_line_offense(node, rhs)
          when :same_line
            check_same_line_offense(node, rhs)
          end
        end

        def check_new_line_offense(node, rhs)
          return unless same_line?(node.loc.operator, rhs)

          add_offense(node, message: NEW_LINE_OFFENSE) do |corrector|
            corrector.insert_after(node.loc.operator, "\n")
          end
        end

        def check_same_line_offense(node, rhs)
          return unless node.loc.operator.line != rhs.first_line

          add_offense(node, message: SAME_LINE_OFFENSE) do |corrector|
            range = range_between(
              node.loc.operator.end_pos, extract_rhs(node).source_range.begin_pos
            )
            corrector.replace(range, ' ')
          end
        end

        private

        def supported_types
          @supported_types ||= cop_config['SupportedTypes'].map(&:to_sym)
        end
      end
    end
  end
end
