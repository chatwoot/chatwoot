# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for space after `!`.
      #
      # @example
      #   # bad
      #   ! something
      #
      #   # good
      #   !something
      class SpaceAfterNot < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Do not leave space between `!` and its argument.'
        RESTRICT_ON_SEND = %i[!].freeze

        def on_send(node)
          return unless node.prefix_bang? && whitespace_after_operator?(node)

          add_offense(node) do |corrector|
            corrector.remove(
              range_between(node.loc.selector.end_pos, node.receiver.source_range.begin_pos)
            )
          end
        end

        private

        def whitespace_after_operator?(node)
          node.receiver.source_range.begin_pos - node.source_range.begin_pos > 1
        end
      end
    end
  end
end
