# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of Proc.new where Kernel#proc
      # would be more appropriate.
      #
      # @example
      #   # bad
      #   p = Proc.new { |n| puts n }
      #
      #   # good
      #   p = proc { |n| puts n }
      #
      class Proc < Base
        extend AutoCorrector

        MSG = 'Use `proc` instead of `Proc.new`.'

        # @!method proc_new?(node)
        def_node_matcher :proc_new?, '(any_block $(send (const {nil? cbase} :Proc) :new) ...)'

        def on_block(node)
          proc_new?(node) do |block_method|
            add_offense(block_method) do |corrector|
              corrector.replace(block_method, 'proc')
            end
          end
        end

        alias on_numblock on_block
        alias on_itblock on_block
      end
    end
  end
end
