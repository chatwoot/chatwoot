# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks uses of the `then` keyword in multi-line `in` statement.
      #
      # @example
      #   # bad
      #   case expression
      #   in pattern then
      #   end
      #
      #   # good
      #   case expression
      #   in pattern
      #   end
      #
      #   # good
      #   case expression
      #   in pattern then do_something
      #   end
      #
      #   # good
      #   case expression
      #   in pattern then do_something(arg1,
      #                                arg2)
      #   end
      #
      class MultilineInPatternThen < Base
        include RangeHelp
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.7

        MSG = 'Do not use `then` for multiline `in` statement.'

        def on_in_pattern(node)
          return if !node.then? || require_then?(node)

          range = node.loc.begin
          add_offense(range) do |corrector|
            corrector.remove(range_with_surrounding_space(range, side: :left, newlines: false))
          end
        end

        private

        # Requires `then` for write `in` and its body on the same line.
        def require_then?(in_pattern_node)
          return true unless in_pattern_node.pattern.single_line?
          return false unless in_pattern_node.body

          same_line?(in_pattern_node, in_pattern_node.body)
        end
      end
    end
  end
end
