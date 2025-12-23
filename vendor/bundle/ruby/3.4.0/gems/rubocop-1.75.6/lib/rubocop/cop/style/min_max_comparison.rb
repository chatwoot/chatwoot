# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use of `max` or `min` instead of comparison for greater or less.
      #
      # NOTE: It can be used if you want to present limit or threshold in Ruby 2.7+.
      # That it is slow though. So autocorrection will apply generic `max` or `min`:
      #
      # [source,ruby]
      # ----
      # a.clamp(b..) # Same as `[a, b].max`
      # a.clamp(..b) # Same as `[a, b].min`
      # ----
      #
      # @safety
      #   This cop is unsafe because even if a value has `<` or `>` method,
      #   it is not necessarily `Comparable`.
      #
      # @example
      #
      #   # bad
      #   a > b ? a : b
      #   a >= b ? a : b
      #
      #   # good
      #   [a, b].max
      #
      #   # bad
      #   a < b ? a : b
      #   a <= b ? a : b
      #
      #   # good
      #   [a, b].min
      #
      class MinMaxComparison < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `%<prefer>s` instead.'
        GRATER_OPERATORS = %i[> >=].freeze
        LESS_OPERATORS = %i[< <=].freeze
        COMPARISON_OPERATORS = GRATER_OPERATORS + LESS_OPERATORS

        def on_if(node)
          lhs, operator, rhs = *node.condition
          return unless COMPARISON_OPERATORS.include?(operator)

          if_branch = node.if_branch
          else_branch = node.else_branch
          preferred_method = preferred_method(operator, lhs, rhs, if_branch, else_branch)
          return unless preferred_method

          replacement = "[#{lhs.source}, #{rhs.source}].#{preferred_method}"

          add_offense(node, message: format(MSG, prefer: replacement)) do |corrector|
            autocorrect(corrector, node, replacement)
          end
        end

        private

        def preferred_method(operator, lhs, rhs, if_branch, else_branch)
          if lhs == if_branch && rhs == else_branch
            GRATER_OPERATORS.include?(operator) ? 'max' : 'min'
          elsif lhs == else_branch && rhs == if_branch
            LESS_OPERATORS.include?(operator) ? 'max' : 'min'
          end
        end

        def autocorrect(corrector, node, replacement)
          if node.elsif?
            corrector.remove(range_between(node.parent.loc.else.begin_pos, node.loc.else.begin_pos))
            corrector.replace(node.else_branch, replacement)
          else
            corrector.replace(node, replacement)
          end
        end
      end
    end
  end
end
