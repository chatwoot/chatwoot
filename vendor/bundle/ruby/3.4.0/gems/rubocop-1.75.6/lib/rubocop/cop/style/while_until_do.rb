# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of `do` in multi-line `while/until` statements.
      #
      # @example
      #
      #   # bad
      #   while x.any? do
      #     do_something(x.pop)
      #   end
      #
      #   # good
      #   while x.any?
      #     do_something(x.pop)
      #   end
      #
      #   # bad
      #   until x.empty? do
      #     do_something(x.pop)
      #   end
      #
      #   # good
      #   until x.empty?
      #     do_something(x.pop)
      #   end
      class WhileUntilDo < Base
        extend AutoCorrector

        MSG = 'Do not use `do` with multi-line `%<keyword>s`.'

        def on_while(node)
          return unless node.multiline? && node.do?

          add_offense(node.loc.begin, message: format(MSG, keyword: node.keyword)) do |corrector|
            do_range = node.condition.source_range.end.join(node.loc.begin)

            corrector.remove(do_range)
          end
        end
        alias on_until on_while
      end
    end
  end
end
