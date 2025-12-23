# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      # Checks if the length of a block exceeds some maximum value.
      # Comment lines can optionally be ignored.
      # The maximum allowed length is configurable.
      # The cop can be configured to ignore blocks passed to certain methods.
      #
      # You can set constructs you want to fold with `CountAsOne`.
      #
      # Available are: 'array', 'hash', 'heredoc', and 'method_call'.
      # Each construct will be counted as one line regardless of its actual size.
      #
      # NOTE: This cop does not apply for `Struct` definitions.
      #
      # NOTE: The `ExcludedMethods` configuration is deprecated and only kept
      # for backwards compatibility. Please use `AllowedMethods` and `AllowedPatterns`
      # instead. By default, there are no methods to allowed.
      #
      # @example CountAsOne: ['array', 'hash', 'heredoc', 'method_call']
      #
      #   something do
      #     array = [         # +1
      #       1,
      #       2
      #     ]
      #
      #     hash = {          # +1
      #       key: 'value'
      #     }
      #
      #     msg = <<~HEREDOC  # +1
      #       Heredoc
      #       content.
      #     HEREDOC
      #
      #     foo(              # +1
      #       1,
      #       2
      #     )
      #   end                 # 4 points
      #
      class BlockLength < Base
        include CodeLength
        include AllowedMethods
        include AllowedPattern

        LABEL = 'Block'

        def on_block(node)
          return if allowed_method?(node.method_name) || matches_allowed_pattern?(node.method_name)
          return if method_receiver_excluded?(node)
          return if node.class_constructor?

          check_code_length(node)
        end
        alias on_numblock on_block
        alias on_itblock on_block

        private

        def method_receiver_excluded?(node)
          node_receiver = node.receiver&.source&.gsub(/\s+/, '')
          node_method = String(node.method_name)

          allowed_methods.any? do |config|
            next unless config.is_a?(String)

            receiver, method = config.split('.')

            unless method
              method = receiver
              receiver = node_receiver
            end

            method == node_method && receiver == node_receiver
          end
        end

        def cop_label
          LABEL
        end
      end
    end
  end
end
