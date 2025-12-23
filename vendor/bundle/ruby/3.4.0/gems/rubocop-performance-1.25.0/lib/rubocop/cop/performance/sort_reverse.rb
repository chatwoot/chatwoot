# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where `sort { |a, b| b <=> a }`
      # can be replaced by a faster `sort.reverse`.
      #
      # @example
      #   # bad
      #   array.sort { |a, b| b <=> a }
      #
      #   # good
      #   array.sort.reverse
      #
      class SortReverse < Base
        include SortBlock
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead.'

        def on_block(node)
          sort_with_block?(node) do |send, var_a, var_b, body|
            replaceable_body?(body, var_b, var_a) do
              register_offense(send, node)
            end
          end
        end

        def on_numblock(node)
          sort_with_numblock?(node) do |send, arg_count, body|
            next unless arg_count == 2

            replaceable_body?(body, :_2, :_1) do
              register_offense(send, node)
            end
          end
        end

        private

        def register_offense(send, node)
          range = sort_range(send, node)
          prefer = "sort#{send.loc.dot.source}reverse"

          message = format(MSG, prefer: prefer)

          add_offense(range, message: message) do |corrector|
            corrector.replace(range, prefer)
          end
        end
      end
    end
  end
end
