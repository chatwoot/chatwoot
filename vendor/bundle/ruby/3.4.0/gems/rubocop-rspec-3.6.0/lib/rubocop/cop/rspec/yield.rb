# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for calling a block within a stub.
      #
      # @example
      #   # bad
      #   allow(foo).to receive(:bar) { |&block| block.call(1) }
      #
      #   # good
      #   expect(foo).to receive(:bar).and_yield(1)
      #
      class Yield < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `.and_yield`.'

        # @!method method_on_stub?(node)
        def_node_search :method_on_stub?, '(send nil? :receive ...)'

        # @!method block_arg(node)
        def_node_matcher :block_arg, '(args (blockarg $_))'

        # @!method block_call?(node)
        def_node_matcher :block_call?, '(send (lvar %) :call ...)'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless method_on_stub?(node.send_node)

          block_arg(node.arguments) do |block|
            if calling_block?(node.body, block)
              range = block_range(node)

              add_offense(range) do |corrector|
                autocorrect(corrector, node, range)
              end
            end
          end
        end

        private

        def autocorrect(corrector, node, range)
          corrector.replace(
            range_with_surrounding_space(range, side: :left),
            generate_replacement(node.body)
          )
        end

        def calling_block?(node, block)
          if node.begin_type?
            node.each_child_node.all? { |child| block_call?(child, block) }
          else
            block_call?(node, block)
          end
        end

        def block_range(node)
          node.loc.begin.with(end_pos: node.loc.end.end_pos)
        end

        def generate_replacement(node)
          if node.begin_type?
            node.children.map { |child| convert_block_to_yield(child) }.join
          else
            convert_block_to_yield(node)
          end
        end

        def convert_block_to_yield(node)
          args = node.arguments
          replacement = '.and_yield'
          replacement += "(#{args.map(&:source).join(', ')})" if args.any?
          replacement
        end
      end
    end
  end
end
