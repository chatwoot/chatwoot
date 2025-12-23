# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if there is an empty line after subject block.
      #
      # @example
      #   # bad
      #   subject(:obj) { described_class }
      #   let(:foo) { bar }
      #
      #   # good
      #   subject(:obj) { described_class }
      #
      #   let(:foo) { bar }
      #
      class EmptyLineAfterSubject < Base
        extend AutoCorrector
        include EmptyLineSeparation
        include InsideExampleGroup

        MSG = 'Add an empty line after `%<subject>s`.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless subject?(node)
          return unless inside_example_group?(node)

          missing_separating_line_offense(node) do |method|
            format(MSG, subject: method)
          end
        end
      end
    end
  end
end
