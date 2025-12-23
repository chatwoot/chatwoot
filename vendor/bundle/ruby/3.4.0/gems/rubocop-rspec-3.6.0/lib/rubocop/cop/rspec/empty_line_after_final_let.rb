# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if there is an empty line after the last let block.
      #
      # @example
      #   # bad
      #   let(:foo) { bar }
      #   let(:something) { other }
      #   it { does_something }
      #
      #   # good
      #   let(:foo) { bar }
      #   let(:something) { other }
      #
      #   it { does_something }
      #
      class EmptyLineAfterFinalLet < Base
        extend AutoCorrector
        include EmptyLineSeparation

        MSG = 'Add an empty line after the last `%<let>s`.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example_group_with_body?(node)

          final_let = node.body.child_nodes.reverse.find { |child| let?(child) }

          return if final_let.nil?

          missing_separating_line_offense(final_let) do |method|
            format(MSG, let: method)
          end
        end
      end
    end
  end
end
