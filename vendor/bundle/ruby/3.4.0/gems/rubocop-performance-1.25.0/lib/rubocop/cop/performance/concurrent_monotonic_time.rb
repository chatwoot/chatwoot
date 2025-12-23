# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where `Concurrent.monotonic_time`
      # can be replaced by `Process.clock_gettime(Process::CLOCK_MONOTONIC)`.
      #
      # @example
      #
      #   # bad
      #   Concurrent.monotonic_time
      #
      #   # good
      #   Process.clock_gettime(Process::CLOCK_MONOTONIC)
      #
      class ConcurrentMonotonicTime < Base
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead of `%<current>s`.'
        RESTRICT_ON_SEND = %i[monotonic_time].freeze

        def_node_matcher :concurrent_monotonic_time?, <<~PATTERN
          (send
            (const {nil? cbase} :Concurrent) :monotonic_time ...)
        PATTERN

        def on_send(node)
          return unless concurrent_monotonic_time?(node)

          optional_unit_parameter = ", #{node.first_argument.source}" if node.first_argument
          prefer = "Process.clock_gettime(Process::CLOCK_MONOTONIC#{optional_unit_parameter})"
          message = format(MSG, prefer: prefer, current: node.source)

          add_offense(node, message: message) do |corrector|
            corrector.replace(node, prefer)
          end
        end
      end
    end
  end
end
