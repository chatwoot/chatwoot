# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if there is an empty line after example blocks.
      #
      # @example
      #   # bad
      #   RSpec.describe Foo do
      #     it 'does this' do
      #     end
      #     it 'does that' do
      #     end
      #   end
      #
      #   # good
      #   RSpec.describe Foo do
      #     it 'does this' do
      #     end
      #
      #     it 'does that' do
      #     end
      #   end
      #
      #   # fair - it's ok to have non-separated one-liners
      #   RSpec.describe Foo do
      #     it { one }
      #     it { two }
      #   end
      #
      # @example with AllowConsecutiveOneLiners configuration
      #   # rubocop.yml
      #   # RSpec/EmptyLineAfterExample:
      #   #   AllowConsecutiveOneLiners: false
      #
      #   # bad
      #   RSpec.describe Foo do
      #     it { one }
      #     it { two }
      #   end
      #
      class EmptyLineAfterExample < Base
        extend AutoCorrector
        include EmptyLineSeparation

        MSG = 'Add an empty line after `%<example>s`.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example?(node)
          return if allowed_one_liner?(node)

          missing_separating_line_offense(node) do |method|
            format(MSG, example: method)
          end
        end

        private

        def allowed_one_liner?(node)
          consecutive_one_liner?(node) && allow_consecutive_one_liners?
        end

        def allow_consecutive_one_liners?
          cop_config['AllowConsecutiveOneLiners']
        end

        def consecutive_one_liner?(node)
          node.single_line? && next_one_line_example?(node)
        end

        def next_one_line_example?(node)
          next_sibling = node.right_sibling
          return false unless next_sibling
          return false unless example?(next_sibling)

          next_sibling.single_line?
        end
      end
    end
  end
end
