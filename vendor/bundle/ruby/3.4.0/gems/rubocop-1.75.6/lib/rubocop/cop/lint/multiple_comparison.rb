# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # In math and Python, we can use `x < y < z` style comparison to compare
      # multiple value. However, we can't use the comparison in Ruby. However,
      # the comparison is not syntax error. This cop checks the bad usage of
      # comparison operators.
      #
      # @example
      #
      #   # bad
      #   x < y < z
      #   10 <= x <= 20
      #
      #   # good
      #   x < y && y < z
      #   10 <= x && x <= 20
      class MultipleComparison < Base
        extend AutoCorrector

        MSG = 'Use the `&&` operator to compare multiple values.'
        COMPARISON_METHODS = %i[< > <= >=].freeze
        SET_OPERATION_OPERATORS = %i[& | ^].freeze
        RESTRICT_ON_SEND = COMPARISON_METHODS

        # @!method multiple_compare?(node)
        def_node_matcher :multiple_compare?, <<~PATTERN
          (send (send _ {:< :> :<= :>=} $_) {:#{COMPARISON_METHODS.join(' :')}} _)
        PATTERN

        def on_send(node)
          return unless (center = multiple_compare?(node))
          # It allows multiple comparison using `&`, `|`, and `^` set operation operators.
          # e.g. `x >= y & y < z`
          return if center.send_type? && SET_OPERATION_OPERATORS.include?(center.method_name)

          add_offense(node) do |corrector|
            new_center = "#{center.source} && #{center.source}"

            corrector.replace(center, new_center)
          end
        end
      end
    end
  end
end
