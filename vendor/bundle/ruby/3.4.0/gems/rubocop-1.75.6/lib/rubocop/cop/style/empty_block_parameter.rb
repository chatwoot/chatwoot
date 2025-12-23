# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for pipes for empty block parameters. Pipes for empty
      # block parameters do not cause syntax errors, but they are redundant.
      #
      # @example
      #   # bad
      #   a do ||
      #     do_something
      #   end
      #
      #   # bad
      #   a { || do_something }
      #
      #   # good
      #   a do
      #   end
      #
      #   # good
      #   a { do_something }
      class EmptyBlockParameter < Base
        include EmptyParameter
        include RangeHelp
        extend AutoCorrector

        MSG = 'Omit pipes for the empty block parameters.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          send_node = node.send_node
          check(node) unless send_node.send_type? && send_node.lambda_literal?
        end

        private

        def autocorrect(corrector, node)
          block = node.parent
          range = range_between(block.loc.begin.end_pos, node.source_range.end_pos)

          corrector.remove(range)
        end
      end
    end
  end
end
