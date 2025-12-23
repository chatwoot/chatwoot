# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if an example contains any expectation.
      #
      # All RSpec's example and expectation methods are covered by default.
      # If you are using your own custom methods,
      # add the following configuration:
      #
      #   RSpec:
      #     Language:
      #       Examples:
      #         Regular:
      #           - custom_it
      #       Expectations:
      #         - custom_expect
      #
      # @example
      #   # bad
      #   it do
      #     a?
      #   end
      #
      #   # good
      #   it do
      #     expect(a?).to be(true)
      #   end
      #
      # This cop can be customized with an allowed expectation methods pattern
      # with an `AllowedPatterns` option. ^expect_ and ^assert_ are allowed
      # by default.
      #
      # @example `AllowedPatterns` configuration
      #
      #   # .rubocop.yml
      #   # RSpec/NoExpectationExample:
      #   #   AllowedPatterns:
      #   #     - ^expect_
      #   #     - ^assert_
      #
      # @example
      #   # bad
      #   it do
      #     not_expect_something
      #   end
      #
      #   # good
      #   it do
      #     expect_something
      #   end
      #
      #   it do
      #     assert_something
      #   end
      #
      class NoExpectationExample < Base
        include AllowedPattern
        include SkipOrPending

        MSG = 'No expectation found in this example.'

        # @!method regular_or_focused_example?(node)
        # @param [RuboCop::AST::Node] node
        # @return [Boolean]
        def_node_matcher :regular_or_focused_example?, <<~PATTERN
          (any_block (send nil? {#Examples.regular #Examples.focused} ...) ...)
        PATTERN

        # @!method includes_expectation?(node)
        # @param [RuboCop::AST::Node] node
        # @return [Boolean]
        def_node_search :includes_expectation?, <<~PATTERN
          {
            (send nil? #Expectations.all ...)
            (send nil? `#matches_allowed_pattern? ...)
          }
        PATTERN

        # @!method includes_skip_example?(node)
        # @param [RuboCop::AST::Node] node
        # @return [Boolean]
        def_node_search :includes_skip_example?, <<~PATTERN
          (send nil? {:pending :skip} ...)
        PATTERN

        # @param [RuboCop::AST::BlockNode] node
        def on_block(node)
          return unless regular_or_focused_example?(node)
          return if includes_expectation?(node)
          return if includes_skip_example?(node)
          return if skipped_in_metadata?(node.send_node)

          add_offense(node)
        end

        alias on_numblock on_block
      end
    end
  end
end
