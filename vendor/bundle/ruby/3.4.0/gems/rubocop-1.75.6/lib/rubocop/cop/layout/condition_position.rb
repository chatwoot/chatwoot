# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for conditions that are not on the same line as
      # if/while/until.
      #
      # @example
      #
      #   # bad
      #   if
      #     some_condition
      #     do_something
      #   end
      #
      #   # good
      #   if some_condition
      #     do_something
      #   end
      class ConditionPosition < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Place the condition on the same line as `%<keyword>s`.'

        def on_if(node)
          return if node.ternary?

          check(node)
        end

        def on_while(node)
          check(node)
        end
        alias on_until on_while

        private

        def check(node)
          return if node.modifier_form? || node.single_line_condition?

          condition = node.condition
          message = message(condition)

          add_offense(condition, message: message) do |corrector|
            range = range_by_whole_lines(condition.source_range, include_final_newline: true)

            corrector.insert_after(condition.parent.loc.keyword, " #{condition.source}")
            corrector.remove(range)
          end
        end

        def message(condition)
          format(MSG, keyword: condition.parent.keyword)
        end
      end
    end
  end
end
