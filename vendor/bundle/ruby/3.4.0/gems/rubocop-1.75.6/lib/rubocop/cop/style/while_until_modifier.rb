# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for while and until statements that would fit on one line
      # if written as a modifier while/until. The maximum line length is
      # configured in the `Layout/LineLength` cop.
      #
      # @example
      #   # bad
      #   while x < 10
      #     x += 1
      #   end
      #
      #   # good
      #   x += 1 while x < 10
      #
      #   # bad
      #   until x > 10
      #     x += 1
      #   end
      #
      #   # good
      #   x += 1 until x > 10
      #
      #   # bad
      #   x += 100 while x < 500 # a long comment that makes code too long if it were a single line
      #
      #   # good
      #   while x < 500 # a long comment that makes code too long if it were a single line
      #     x += 100
      #   end
      class WhileUntilModifier < Base
        include StatementModifier
        extend AutoCorrector

        MSG = 'Favor modifier `%<keyword>s` usage when having a single-line body.'

        def on_while(node)
          return unless single_line_as_modifier?(node)

          add_offense(node.loc.keyword, message: format(MSG, keyword: node.keyword)) do |corrector|
            corrector.replace(node, to_modifier_form(node))
          end
        end
        alias on_until on_while
      end
    end
  end
end
