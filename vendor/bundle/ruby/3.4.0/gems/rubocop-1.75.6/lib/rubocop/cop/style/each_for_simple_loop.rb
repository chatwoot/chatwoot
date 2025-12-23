# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for loops which iterate a constant number of times,
      # using a `Range` literal and `#each`. This can be done more readably using
      # `Integer#times`.
      #
      # This check only applies if the block takes no parameters.
      #
      # @example
      #   # bad
      #   (1..5).each { }
      #
      #   # good
      #   5.times { }
      #
      #   # bad
      #   (0...10).each {}
      #
      #   # good
      #   10.times {}
      class EachForSimpleLoop < Base
        extend AutoCorrector

        MSG = 'Use `Integer#times` for a simple loop which iterates a fixed number of times.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless offending?(node)

          send_node = node.send_node

          add_offense(send_node) do |corrector|
            range_type, min, max = each_range(node)

            max += 1 if range_type == :irange

            corrector.replace(send_node, "#{max - min}.times")
          end
        end

        private

        def offending?(node)
          return false unless node.arguments.empty?

          each_range_with_zero_origin?(node) || each_range_without_block_argument?(node)
        end

        # @!method each_range(node)
        def_node_matcher :each_range, <<~PATTERN
          (block
            (call
              (begin
                ($range (int $_) (int $_)))
              :each)
            (args ...)
            ...)
        PATTERN

        # @!method each_range_with_zero_origin?(node)
        def_node_matcher :each_range_with_zero_origin?, <<~PATTERN
          (block
            (call
              (begin
                (range (int 0) (int _)))
              :each)
            (args ...)
            ...)
        PATTERN

        # @!method each_range_without_block_argument?(node)
        def_node_matcher :each_range_without_block_argument?, <<~PATTERN
          (block
            (call
              (begin
                (range (int _) (int _)))
              :each)
            (args)
            ...)
        PATTERN
      end
    end
  end
end
