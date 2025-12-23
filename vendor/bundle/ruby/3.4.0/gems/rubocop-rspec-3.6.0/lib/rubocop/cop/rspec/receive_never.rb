# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Prefer `not_to receive(...)` over `receive(...).never`.
      #
      # @example
      #   # bad
      #   expect(foo).to receive(:bar).never
      #
      #   # good
      #   expect(foo).not_to receive(:bar)
      #
      class ReceiveNever < Base
        extend AutoCorrector
        MSG = 'Use `not_to receive` instead of `never`.'
        RESTRICT_ON_SEND = %i[never].freeze

        # @!method method_on_stub?(node)
        def_node_search :method_on_stub?, '(send nil? :receive ...)'

        def on_send(node)
          return unless node.method?(:never) && method_on_stub?(node)

          add_offense(node.loc.selector) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def autocorrect(corrector, node)
          corrector.replace(node.parent.loc.selector, 'not_to')
          range = node.loc.dot.with(end_pos: node.loc.selector.end_pos)
          corrector.remove(range)
        end
      end
    end
  end
end
