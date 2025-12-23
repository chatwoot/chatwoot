# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where `sort { |a, b| a <=> b }` can be replaced with `sort`.
      #
      # @example
      #   # bad
      #   array.sort { |a, b| a <=> b }
      #
      #   # good
      #   array.sort
      #
      class RedundantSortBlock < Base
        include SortBlock
        extend AutoCorrector

        MSG = 'Use `sort` without block.'

        def on_block(node)
          return unless (send, var_a, var_b, body = sort_with_block?(node))

          replaceable_body?(body, var_a, var_b) do
            register_offense(send, node)
          end
        end

        def on_numblock(node)
          return unless (send, arg_count, body = sort_with_numblock?(node))
          return unless arg_count == 2

          replaceable_body?(body, :_1, :_2) do
            register_offense(send, node)
          end
        end

        private

        def register_offense(send, node)
          range = sort_range(send, node)

          add_offense(range) do |corrector|
            corrector.replace(range, 'sort')
          end
        end
      end
    end
  end
end
