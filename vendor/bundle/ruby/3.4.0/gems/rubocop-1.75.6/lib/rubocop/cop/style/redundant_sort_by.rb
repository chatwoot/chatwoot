# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Identifies places where `sort_by { ... }` can be replaced by
      # `sort`.
      #
      # @example
      #   # bad
      #   array.sort_by { |x| x }
      #   array.sort_by do |var|
      #     var
      #   end
      #
      #   # good
      #   array.sort
      class RedundantSortBy < Base
        include RangeHelp
        extend AutoCorrector

        MSG_BLOCK = 'Use `sort` instead of `sort_by { |%<var>s| %<var>s }`.'
        MSG_NUMBLOCK = 'Use `sort` instead of `sort_by { _1 }`.'
        MSG_ITBLOCK = 'Use `sort` instead of `sort_by { it }`.'

        def on_block(node)
          redundant_sort_by_block(node) do |send, var_name|
            range = sort_by_range(send, node)

            add_offense(range, message: format(MSG_BLOCK, var: var_name)) do |corrector|
              corrector.replace(range, 'sort')
            end
          end
        end

        def on_numblock(node)
          redundant_sort_by_numblock(node) do |send|
            range = sort_by_range(send, node)

            add_offense(range, message: MSG_NUMBLOCK) do |corrector|
              corrector.replace(range, 'sort')
            end
          end
        end

        def on_itblock(node)
          redundant_sort_by_itblock(node) do |send|
            range = sort_by_range(send, node)

            add_offense(range, message: MSG_ITBLOCK) do |corrector|
              corrector.replace(range, 'sort')
            end
          end
        end

        private

        # @!method redundant_sort_by_block(node)
        def_node_matcher :redundant_sort_by_block, <<~PATTERN
          (block $(call _ :sort_by) (args (arg $_x)) (lvar _x))
        PATTERN

        # @!method redundant_sort_by_numblock(node)
        def_node_matcher :redundant_sort_by_numblock, <<~PATTERN
          (numblock $(call _ :sort_by) 1 (lvar :_1))
        PATTERN

        # @!method redundant_sort_by_itblock(node)
        def_node_matcher :redundant_sort_by_itblock, <<~PATTERN
          (itblock $(call _ :sort_by) _ (lvar :it))
        PATTERN

        def sort_by_range(send, node)
          range_between(send.loc.selector.begin_pos, node.loc.end.end_pos)
        end
      end
    end
  end
end
