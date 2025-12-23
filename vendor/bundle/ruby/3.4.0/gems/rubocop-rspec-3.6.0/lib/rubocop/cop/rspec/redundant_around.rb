# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Remove redundant `around` hook.
      #
      # @example
      #   # bad
      #   around do |example|
      #     example.run
      #   end
      #
      #   # good
      #
      class RedundantAround < Base
        extend AutoCorrector

        MSG = 'Remove redundant `around` hook.'

        RESTRICT_ON_SEND = %i[around].freeze

        def on_block(node)
          return unless match_redundant_around_hook_block?(node)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end
        alias on_numblock on_block

        def on_send(node)
          return unless match_redundant_around_hook_send?(node)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        # @!method match_redundant_around_hook_block?(node)
        def_node_matcher :match_redundant_around_hook_block?, <<~PATTERN
          (any_block (send _ :around ...) ... (send _ :run))
        PATTERN

        # @!method match_redundant_around_hook_send?(node)
        def_node_matcher :match_redundant_around_hook_send?, <<~PATTERN
          (send
            _
            :around
            ...
            (block-pass
              (sym :run)
            )
          )
        PATTERN

        def autocorrect(corrector, node)
          corrector.remove(node)
        end
      end
    end
  end
end
