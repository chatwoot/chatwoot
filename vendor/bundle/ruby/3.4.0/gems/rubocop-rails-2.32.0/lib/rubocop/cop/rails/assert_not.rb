# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Use `assert_not` instead of `assert !`.
      #
      # @example
      #   # bad
      #   assert !x
      #
      #   # good
      #   assert_not x
      #
      class AssertNot < Base
        extend AutoCorrector

        MSG = 'Prefer `assert_not` over `assert !`.'
        RESTRICT_ON_SEND = %i[assert].freeze

        def_node_matcher :offensive?, '(send nil? :assert (send ... :!) ...)'

        def on_send(node)
          return unless offensive?(node)

          add_offense(node) do |corrector|
            expression = node.source_range

            corrector.replace(expression, corrected_source(expression.source))
          end
        end

        private

        def corrected_source(source)
          source.gsub(/^assert(\(| ) *! */, 'assert_not\\1')
        end
      end
    end
  end
end
