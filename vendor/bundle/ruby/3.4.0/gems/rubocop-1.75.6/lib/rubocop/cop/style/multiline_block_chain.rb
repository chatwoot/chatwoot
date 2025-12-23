# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for chaining of a block after another block that spans
      # multiple lines.
      #
      # @example
      #
      #   # bad
      #   Thread.list.select do |t|
      #     t.alive?
      #   end.map do |t|
      #     t.object_id
      #   end
      #
      #   # good
      #   alive_threads = Thread.list.select do |t|
      #     t.alive?
      #   end
      #   alive_threads.map do |t|
      #     t.object_id
      #   end
      class MultilineBlockChain < Base
        include RangeHelp

        MSG = 'Avoid multi-line chains of blocks.'

        def on_block(node)
          node.send_node.each_node(:call) do |send_node|
            receiver = send_node.receiver

            next unless receiver&.any_block_type? && receiver.multiline?

            range = range_between(receiver.loc.end.begin_pos, node.send_node.source_range.end_pos)

            add_offense(range)

            # Done. If there are more blocks in the chain, they will be
            # found by subsequent calls to on_block.
            break
          end
        end

        alias on_numblock on_block
        alias on_itblock on_block
      end
    end
  end
end
