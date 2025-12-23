# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for passing a block to `skip` within examples.
      #
      # @example
      #   # bad
      #   it 'does something' do
      #     skip 'not yet implemented' do
      #       do_something
      #     end
      #   end
      #
      #   # good
      #   it 'does something' do
      #     skip 'not yet implemented'
      #     do_something
      #   end
      #
      #   # good - when outside example
      #   skip 'not yet implemented' do
      #   end
      #
      class SkipBlockInsideExample < Base
        MSG = "Don't pass a block to `skip` inside examples."

        def on_block(node)
          return unless node.method?(:skip)
          return unless inside_example?(node)

          add_offense(node)
        end

        alias on_numblock on_block

        private

        def inside_example?(node)
          node.each_ancestor(:block).any? { |ancestor| example?(ancestor) }
        end
      end
    end
  end
end
