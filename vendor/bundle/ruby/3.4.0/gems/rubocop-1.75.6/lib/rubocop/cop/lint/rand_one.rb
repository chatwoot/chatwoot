# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for `rand(1)` calls.
      # Such calls always return `0`.
      #
      # @example
      #
      #   # bad
      #   rand 1
      #   Kernel.rand(-1)
      #   rand 1.0
      #   rand(-1.0)
      #
      #   # good
      #   0 # just use 0 instead
      class RandOne < Base
        MSG = '`%<method>s` always returns `0`. Perhaps you meant `rand(2)` or `rand`?'
        RESTRICT_ON_SEND = %i[rand].freeze

        # @!method rand_one?(node)
        def_node_matcher :rand_one?, <<~PATTERN
          (send {(const {nil? cbase} :Kernel) nil?} :rand {(int {-1 1}) (float {-1.0 1.0})})
        PATTERN

        def on_send(node)
          return unless rand_one?(node)

          add_offense(node)
        end

        private

        def message(node)
          format(MSG, method: node.source)
        end
      end
    end
  end
end
