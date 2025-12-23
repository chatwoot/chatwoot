# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if `.to`, `not_to` or `to_not` are used.
      #
      # The RSpec::Expectations::ExpectationTarget must use `to`, `not_to` or
      # `to_not` to run. Therefore, this cop checks if other methods are used.
      #
      # @example
      #   # bad
      #   expect(something).kind_of? Foo
      #   is_expected == 42
      #   expect{something}.eq? BarError
      #
      #   # good
      #   expect(something).to be_a Foo
      #   is_expected.to eq 42
      #   expect{something}.to raise_error BarError
      #
      class MissingExpectationTargetMethod < Base
        MSG = 'Use `.to`, `.not_to` or `.to_not` to set an expectation.'
        RESTRICT_ON_SEND = %i[expect is_expected].freeze

        # @!method expect?(node)
        def_node_matcher :expect?, <<~PATTERN
          {
            (send nil? :expect ...)
            (send nil? :is_expected)
          }
        PATTERN

        # @!method expect_block?(node)
        def_node_matcher :expect_block?, <<~PATTERN
          (block #expect? (args) _body)
        PATTERN

        # @!method expectation_without_runner?(node)
        def_node_matcher :expectation_without_runner?, <<~PATTERN
          (send {#expect? #expect_block?} !#Runners.all ...)
        PATTERN

        def on_send(node)
          node = node.parent if node.parent&.block_type?

          expectation_without_runner?(node.parent) do
            add_offense(node.parent.loc.selector)
          end
        end
      end
    end
  end
end
