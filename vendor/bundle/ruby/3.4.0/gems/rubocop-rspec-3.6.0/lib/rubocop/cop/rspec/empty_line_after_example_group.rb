# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if there is an empty line after example group blocks.
      #
      # @example
      #   # bad
      #   RSpec.describe Foo do
      #     describe '#bar' do
      #     end
      #     describe '#baz' do
      #     end
      #   end
      #
      #   # good
      #   RSpec.describe Foo do
      #     describe '#bar' do
      #     end
      #
      #     describe '#baz' do
      #     end
      #   end
      #
      class EmptyLineAfterExampleGroup < Base
        extend AutoCorrector
        include EmptyLineSeparation

        MSG = 'Add an empty line after `%<example_group>s`.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless spec_group?(node)

          missing_separating_line_offense(node) do |method|
            format(MSG, example_group: method)
          end
        end
      end
    end
  end
end
