# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for uses of the `for` keyword or `each` method. The
      # preferred alternative is set in the EnforcedStyle configuration
      # parameter. An `each` call with a block on a single line is always
      # allowed.
      #
      # @example EnforcedStyle: each (default)
      #   # bad
      #   def foo
      #     for n in [1, 2, 3] do
      #       puts n
      #     end
      #   end
      #
      #   # good
      #   def foo
      #     [1, 2, 3].each do |n|
      #       puts n
      #     end
      #   end
      #
      # @example EnforcedStyle: for
      #   # bad
      #   def foo
      #     [1, 2, 3].each do |n|
      #       puts n
      #     end
      #   end
      #
      #   # good
      #   def foo
      #     for n in [1, 2, 3] do
      #       puts n
      #     end
      #   end
      #
      # @safety
      #   This cop's autocorrection is unsafe because the scope of
      #   variables is different between `each` and `for`.
      #
      class For < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        EACH_LENGTH = 'each'.length
        PREFER_EACH = 'Prefer `each` over `for`.'
        PREFER_FOR = 'Prefer `for` over `each`.'

        def on_for(node)
          if style == :each
            add_offense(node, message: PREFER_EACH) do |corrector|
              ForToEachCorrector.new(node).call(corrector)
              opposite_style_detected
            end
          else
            correct_style_detected
          end
        end

        def on_block(node)
          return unless suspect_enumerable?(node)

          if style == :for
            return unless node.receiver

            add_offense(node, message: PREFER_FOR) do |corrector|
              EachToForCorrector.new(node).call(corrector)
              opposite_style_detected
            end
          else
            correct_style_detected
          end
        end

        alias on_numblock on_block
        alias on_itblock on_block

        private

        def suspect_enumerable?(node)
          node.multiline? && node.method?(:each) && !node.send_node.arguments?
        end
      end
    end
  end
end
