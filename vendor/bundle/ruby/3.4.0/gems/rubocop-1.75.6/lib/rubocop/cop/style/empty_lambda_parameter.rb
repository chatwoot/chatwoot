# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for parentheses for empty lambda parameters. Parentheses
      # for empty lambda parameters do not cause syntax errors, but they are
      # redundant.
      #
      # @example
      #   # bad
      #   -> () { do_something }
      #
      #   # good
      #   -> { do_something }
      #
      #   # good
      #   -> (arg) { do_something(arg) }
      class EmptyLambdaParameter < Base
        include EmptyParameter
        include RangeHelp
        extend AutoCorrector

        MSG = 'Omit parentheses for the empty lambda parameters.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          send_node = node.send_node
          return unless send_node.send_type?

          check(node) if node.send_node.lambda_literal?
        end

        private

        def autocorrect(corrector, node)
          send_node = node.parent.send_node
          range = range_between(send_node.source_range.end_pos, node.source_range.end_pos)

          corrector.remove(range)
        end
      end
    end
  end
end
