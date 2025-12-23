# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of unless with a negated condition. Only unless
      # without else are considered. There are three different styles:
      #
      # * both
      # * prefix
      # * postfix
      #
      # @example EnforcedStyle: both (default)
      #   # enforces `if` for `prefix` and `postfix` conditionals
      #
      #   # bad
      #   unless !foo
      #     bar
      #   end
      #
      #   # good
      #   if foo
      #     bar
      #   end
      #
      #   # bad
      #   bar unless !foo
      #
      #   # good
      #   bar if foo
      #
      # @example EnforcedStyle: prefix
      #   # enforces `if` for just `prefix` conditionals
      #
      #   # bad
      #   unless !foo
      #     bar
      #   end
      #
      #   # good
      #   if foo
      #     bar
      #   end
      #
      #   # good
      #   bar unless !foo
      #
      # @example EnforcedStyle: postfix
      #   # enforces `if` for just `postfix` conditionals
      #
      #   # bad
      #   bar unless !foo
      #
      #   # good
      #   bar if foo
      #
      #   # good
      #   unless !foo
      #     bar
      #   end
      class NegatedUnless < Base
        include ConfigurableEnforcedStyle
        include NegativeConditional
        extend AutoCorrector

        def on_if(node)
          return if node.if? || node.elsif? || node.ternary?
          return if correct_style?(node)

          message = message(node)
          check_negative_conditional(node, message: message) do |corrector|
            ConditionCorrector.correct_negative_condition(corrector, node)
          end
        end

        private

        def message(node)
          format(MSG, inverse: node.inverse_keyword, current: node.keyword)
        end

        def correct_style?(node)
          (style == :prefix && node.modifier_form?) || (style == :postfix && !node.modifier_form?)
        end
      end
    end
  end
end
