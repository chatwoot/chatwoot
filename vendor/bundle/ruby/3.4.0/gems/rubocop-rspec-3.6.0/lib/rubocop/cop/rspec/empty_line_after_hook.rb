# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if there is an empty line after hook blocks.
      #
      # `AllowConsecutiveOneLiners` configures whether adjacent
      # one-line definitions are considered an offense.
      #
      # @example
      #   # bad
      #   before { do_something }
      #   it { does_something }
      #
      #   # bad
      #   after { do_something }
      #   it { does_something }
      #
      #   # bad
      #   around { |test| test.run }
      #   it { does_something }
      #
      #   # good
      #   after { do_something }
      #
      #   it { does_something }
      #
      #   # fair - it's ok to have non-separated one-liners hooks
      #   around { |test| test.run }
      #   after { do_something }
      #
      #   it { does_something }
      #
      # @example with AllowConsecutiveOneLiners configuration
      #   # rubocop.yml
      #   # RSpec/EmptyLineAfterHook:
      #   #   AllowConsecutiveOneLiners: false
      #
      #   # bad
      #   around { |test| test.run }
      #   after { do_something }
      #
      #   it { does_something }
      #
      #   # good
      #   around { |test| test.run }
      #
      #   after { do_something }
      #
      #   it { does_something }
      #
      class EmptyLineAfterHook < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle
        include EmptyLineSeparation

        MSG = 'Add an empty line after `%<hook>s`.'

        def on_block(node)
          return unless hook?(node)
          return if cop_config['AllowConsecutiveOneLiners'] &&
            chained_single_line_hooks?(node)

          missing_separating_line_offense(node) do |method|
            format(MSG, hook: method)
          end
        end

        alias on_numblock on_block

        private

        def chained_single_line_hooks?(node)
          next_node = node.right_sibling

          hook?(next_node) && node.single_line? && next_node.single_line?
        end
      end
    end
  end
end
