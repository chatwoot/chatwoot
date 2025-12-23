# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for methods called on a do...end block. The point of
      # this check is that it's easy to miss the call tacked on to the block
      # when reading code.
      #
      # @example
      #   # bad
      #   a do
      #     b
      #   end.c
      #
      #   # good
      #   a { b }.c
      #
      #   # good
      #   foo = a do
      #     b
      #   end
      #   foo.c
      class MethodCalledOnDoEndBlock < Base
        include RangeHelp

        MSG = 'Avoid chaining a method call on a do...end block.'

        def on_block(node)
          # If the method that is chained on the do...end block is itself a
          # method with a block, we allow it. It's pretty safe to assume that
          # these calls are not missed by anyone reading code. We also want to
          # avoid double reporting of offenses checked by the
          # MultilineBlockChain cop.
          ignore_node(node.send_node)
        end

        alias on_numblock on_block
        alias on_itblock on_block

        def on_send(node)
          return if ignored_node?(node)

          return unless (receiver = node.receiver)
          return unless receiver.any_block_type? && receiver.keywords?

          range = range_between(receiver.loc.end.begin_pos, node.source_range.end_pos)

          add_offense(range)
        end
        alias on_csend on_send
      end
    end
  end
end
