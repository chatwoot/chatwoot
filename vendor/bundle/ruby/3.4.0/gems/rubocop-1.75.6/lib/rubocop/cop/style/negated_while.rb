# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of while with a negated condition.
      #
      # @example
      #   # bad
      #   while !foo
      #     bar
      #   end
      #
      #   # good
      #   until foo
      #     bar
      #   end
      #
      #   # bad
      #   bar until !foo
      #
      #   # good
      #   bar while foo
      #   bar while !foo && baz
      class NegatedWhile < Base
        include NegativeConditional
        extend AutoCorrector

        def on_while(node)
          message = format(MSG, inverse: node.inverse_keyword, current: node.keyword)

          check_negative_conditional(node, message: message) do |corrector|
            ConditionCorrector.correct_negative_condition(corrector, node)
          end
        end
        alias on_until on_while
      end
    end
  end
end
