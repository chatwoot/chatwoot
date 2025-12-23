# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check for `specify` with `is_expected` and one-liner expectations.
      #
      # @example
      #   # bad
      #   specify { is_expected.to be_truthy }
      #
      #   # good
      #   it { is_expected.to be_truthy }
      #
      #   # good
      #   specify do
      #     # ...
      #   end
      #   specify { expect(sqrt(4)).to eq(2) }
      #
      class IsExpectedSpecify < Base
        extend AutoCorrector

        RESTRICT_ON_SEND = %i[specify].freeze
        IS_EXPECTED_METHODS = ::Set[:is_expected, :are_expected].freeze
        MSG = 'Use `it` instead of `specify`.'

        # @!method offense?(node)
        def_node_matcher :offense?, <<~PATTERN
          (block (send _ :specify) _ (send (send _ IS_EXPECTED_METHODS) ...))
        PATTERN

        def on_send(node)
          block_node = node.parent
          return unless block_node&.single_line? && offense?(block_node)

          selector = node.loc.selector
          add_offense(selector) do |corrector|
            corrector.replace(selector, 'it')
          end
        end
      end
    end
  end
end
