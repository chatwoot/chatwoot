# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Checks for calls to `#bytes` counting method and suggests using `bytesize` instead.
      # The `bytesize` method is more efficient and directly returns the size in bytes,
      # avoiding the intermediate array allocation that `bytes.size` incurs.
      #
      # @safety
      #   This cop is unsafe because it assumes that the receiver
      #   responds to `#bytesize` method.
      #
      # @example
      #   # bad
      #   string_var.bytes.count
      #   "foobar".bytes.size
      #
      #   # good
      #   string_var.bytesize
      #   "foobar".bytesize
      class StringBytesize < Base
        extend AutoCorrector

        MSG = 'Use `String#bytesize` instead of calculating the size of the bytes array.'
        RESTRICT_ON_SEND = %i[size length count].freeze

        def_node_matcher :string_bytes_method?, <<~MATCHER
          (call (call !{nil? int} :bytes) {:size :length :count})
        MATCHER

        def on_send(node)
          string_bytes_method?(node) do
            range = node.receiver.loc.selector.begin.join(node.source_range.end)

            add_offense(range) do |corrector|
              corrector.replace(range, 'bytesize')
            end
          end
        end
        alias on_csend on_send
      end
    end
  end
end
