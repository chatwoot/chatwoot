# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for redundant receiver in `with_options`.
      # Receiver is implicit from Rails 4.2 or higher.
      #
      # @example
      #   # bad
      #   class Account < ApplicationRecord
      #     with_options dependent: :destroy do |assoc|
      #       assoc.has_many :customers
      #       assoc.has_many :products
      #       assoc.has_many :invoices
      #       assoc.has_many :expenses
      #     end
      #   end
      #
      #   # good
      #   class Account < ApplicationRecord
      #     with_options dependent: :destroy do
      #       has_many :customers
      #       has_many :products
      #       has_many :invoices
      #       has_many :expenses
      #     end
      #   end
      #
      # @example
      #   # bad
      #   with_options options: false do |merger|
      #     merger.invoke(merger.something)
      #   end
      #
      #   # good
      #   with_options options: false do
      #     invoke(something)
      #   end
      #
      #   # good
      #   client = Client.new
      #   with_options options: false do |merger|
      #     client.invoke(merger.something, something)
      #   end
      #
      #   # ok
      #   # When `with_options` includes a block, all scoping scenarios
      #   # cannot be evaluated. Thus, it is ok to include the explicit
      #   # receiver.
      #   with_options options: false do |merger|
      #     merger.invoke
      #     with_another_method do |another_receiver|
      #       merger.invoke(another_receiver)
      #     end
      #   end
      class RedundantReceiverInWithOptions < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Redundant receiver in `with_options`.'

        def_node_search :all_block_nodes_in, <<~PATTERN
          (block ...)
        PATTERN

        def_node_search :all_send_nodes_in, <<~PATTERN
          (send ...)
        PATTERN

        def on_block(node)
          return unless node.method?(:with_options)
          return unless (body = node.body)
          return unless all_block_nodes_in(body).count.zero?

          send_nodes = all_send_nodes_in(body)
          return unless redundant_receiver?(send_nodes, node)

          send_nodes.each do |send_node|
            receiver = send_node.receiver
            add_offense(receiver) do |corrector|
              autocorrect(corrector, send_node, node)
            end
          end
        end

        alias on_numblock on_block
        alias on_itblock on_block

        private

        def autocorrect(corrector, send_node, node)
          corrector.remove(send_node.receiver)
          corrector.remove(send_node.loc.dot)
          corrector.remove(block_argument_range(send_node)) if node.block_type?
        end

        # rubocop:disable Metrics/AbcSize
        def redundant_receiver?(send_nodes, node)
          proc = if node.numblock_type?
                   ->(n) { n.receiver.lvar_type? && n.receiver.source == '_1' }
                 elsif node.itblock_type?
                   ->(n) { n.receiver.lvar_type? && n.receiver.source == 'it' }
                 else
                   return false if node.arguments.empty?

                   arg = node.first_argument
                   ->(n) { same_value?(arg, n.receiver) }
                 end

          send_nodes.all?(&proc)
        end
        # rubocop:enable Metrics/AbcSize

        def block_argument_range(node)
          block_node = node.each_ancestor(:block).first
          block_argument = block_node.children[1].source_range

          range_between(
            search_begin_pos_of_space_before_block_argument(
              block_argument.begin_pos
            ),
            block_argument.end_pos
          )
        end

        def search_begin_pos_of_space_before_block_argument(begin_pos)
          position = begin_pos - 1

          if processed_source.raw_source[position] == ' '
            search_begin_pos_of_space_before_block_argument(position)
          else
            begin_pos
          end
        end

        def same_value?(arg_node, recv_node)
          recv_node && recv_node.children[0] == arg_node.children[0]
        end
      end
    end
  end
end
