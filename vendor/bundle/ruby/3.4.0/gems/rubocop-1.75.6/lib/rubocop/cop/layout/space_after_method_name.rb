# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for space between a method name and a left parenthesis in defs.
      #
      # @example
      #
      #   # bad
      #   def func (x) end
      #   def method= (y) end
      #
      #   # good
      #   def func(x) end
      #   def method=(y) end
      class SpaceAfterMethodName < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Do not put a space between a method name and the opening parenthesis.'

        def on_def(node)
          args = node.arguments
          return unless args.parenthesized_call?

          expr = args.source_range
          pos_before_left_paren = range_between(expr.begin_pos - 1, expr.begin_pos)
          return unless pos_before_left_paren.source.start_with?(' ')

          add_offense(pos_before_left_paren) do |corrector|
            corrector.remove(pos_before_left_paren)
          end
        end
        alias on_defs on_def
      end
    end
  end
end
