# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for `unless` expressions with `else` clauses.
      #
      # @example
      #   # bad
      #   unless foo_bar.nil?
      #     # do something...
      #   else
      #     # do a different thing...
      #   end
      #
      #   # good
      #   if foo_bar.present?
      #     # do something...
      #   else
      #     # do a different thing...
      #   end
      class UnlessElse < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Do not use `unless` with `else`. Rewrite these with the positive case first.'

        def on_if(node)
          return unless node.unless? && node.else?

          add_offense(node) do |corrector|
            body_range = range_between_condition_and_else(node, node.condition)
            else_range = range_between_else_and_end(node)

            next if part_of_ignored_node?(node)

            corrector.replace(node.loc.keyword, 'if')
            corrector.replace(body_range, else_range.source)
            corrector.replace(else_range, body_range.source)
          end

          ignore_node(node)
        end

        def range_between_condition_and_else(node, condition)
          range_between(condition.source_range.end_pos, node.loc.else.begin_pos)
        end

        def range_between_else_and_end(node)
          range_between(node.loc.else.end_pos, node.loc.end.begin_pos)
        end
      end
    end
  end
end
