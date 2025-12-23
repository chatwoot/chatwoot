# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Sometimes using `dig` method ends up with just a single
      # argument. In such cases, dig should be replaced with `[]`.
      #
      # Since replacing `hash&.dig(:key)` with `hash[:key]` could potentially lead to error,
      # calls to the `dig` method using safe navigation will be ignored.
      #
      # @safety
      #   This cop is unsafe because it cannot be guaranteed that the receiver
      #   is an `Enumerable` or does not have a nonstandard implementation
      #   of `dig`.
      #
      # @example
      #   # bad
      #   { key: 'value' }.dig(:key)
      #   [1, 2, 3].dig(0)
      #
      #   # good
      #   { key: 'value' }[:key]
      #   [1, 2, 3][0]
      #
      #   # good
      #   { key1: { key2: 'value' } }.dig(:key1, :key2)
      #   [1, [2, [3]]].dig(1, 1)
      #
      #   # good
      #   keys = %i[key1 key2]
      #   { key1: { key2: 'value' } }.dig(*keys)
      #
      class SingleArgumentDig < Base
        extend AutoCorrector
        include DigHelp

        MSG = 'Use `%<receiver>s[%<argument>s]` instead of `%<original>s`.'
        RESTRICT_ON_SEND = %i[dig].freeze
        IGNORED_ARGUMENT_TYPES = %i[block_pass forwarded_restarg forwarded_args hash].freeze

        def on_send(node)
          return unless node.receiver

          expression = single_argument_dig?(node)
          return unless expression
          return if IGNORED_ARGUMENT_TYPES.include?(expression.type)
          return if ignore_dig_chain?(node)

          receiver = node.receiver.source
          argument = expression.source

          message = format(MSG, receiver: receiver, argument: argument, original: node.source)
          add_offense(node, message: message) do |corrector|
            next if part_of_ignored_node?(node)

            correct_access = "#{receiver}[#{argument}]"
            corrector.replace(node, correct_access)
          end

          ignore_node(node)
        end

        private

        def ignore_dig_chain?(node)
          dig_chain_enabled? &&
            (dig?(node.receiver) || dig?(node.parent))
        end
      end
    end
  end
end
