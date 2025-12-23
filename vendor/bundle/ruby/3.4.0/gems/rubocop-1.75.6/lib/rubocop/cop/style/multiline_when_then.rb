# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks uses of the `then` keyword
      # in multi-line when statements.
      #
      # @example
      #   # bad
      #   case foo
      #   when bar then
      #   end
      #
      #   # good
      #   case foo
      #   when bar
      #   end
      #
      #   # good
      #   case foo
      #   when bar then do_something
      #   end
      #
      #   # good
      #   case foo
      #   when bar then do_something(arg1,
      #                              arg2)
      #   end
      #
      class MultilineWhenThen < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Do not use `then` for multiline `when` statement.'

        def on_when(node)
          return if !node.then? || require_then?(node)

          range = node.loc.begin
          add_offense(range) do |corrector|
            corrector.remove(range_with_surrounding_space(range, side: :left, newlines: false))
          end
        end

        private

        # Requires `then` for write `when` and its body on the same line.
        def require_then?(when_node)
          unless when_node.conditions.first.first_line == when_node.conditions.last.last_line
            return true
          end
          return false unless when_node.body

          same_line?(when_node, when_node.body)
        end
      end
    end
  end
end
