# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks that the closing brace in a hash literal is either
      # on the same line as the last hash element, or a new line.
      #
      # When using the `symmetrical` (default) style:
      #
      # If a hash's opening brace is on the same line as the first element
      # of the hash, then the closing brace should be on the same line as
      # the last element of the hash.
      #
      # If a hash's opening brace is on the line above the first element
      # of the hash, then the closing brace should be on the line below
      # the last element of the hash.
      #
      # When using the `new_line` style:
      #
      # The closing brace of a multi-line hash literal must be on the line
      # after the last element of the hash.
      #
      # When using the `same_line` style:
      #
      # The closing brace of a multi-line hash literal must be on the same
      # line as the last element of the hash.
      #
      # @example EnforcedStyle: symmetrical (default)
      #
      #     # bad
      #     { a: 1,
      #       b: 2
      #     }
      #     # bad
      #     {
      #       a: 1,
      #       b: 2 }
      #
      #     # good
      #     { a: 1,
      #       b: 2 }
      #
      #     # good
      #     {
      #       a: 1,
      #       b: 2
      #     }
      #
      # @example EnforcedStyle: new_line
      #     # bad
      #     {
      #       a: 1,
      #       b: 2 }
      #
      #     # bad
      #     { a: 1,
      #       b: 2 }
      #
      #     # good
      #     { a: 1,
      #       b: 2
      #     }
      #
      #     # good
      #     {
      #       a: 1,
      #       b: 2
      #     }
      #
      # @example EnforcedStyle: same_line
      #     # bad
      #     { a: 1,
      #       b: 2
      #     }
      #
      #     # bad
      #     {
      #       a: 1,
      #       b: 2
      #     }
      #
      #     # good
      #     {
      #       a: 1,
      #       b: 2 }
      #
      #     # good
      #     { a: 1,
      #       b: 2 }
      class MultilineHashBraceLayout < Base
        include MultilineLiteralBraceLayout
        extend AutoCorrector

        SAME_LINE_MESSAGE = 'Closing hash brace must be on the same line as ' \
                            'the last hash element when opening brace is on the same line as ' \
                            'the first hash element.'

        NEW_LINE_MESSAGE = 'Closing hash brace must be on the line after ' \
                           'the last hash element when opening brace is on a separate line ' \
                           'from the first hash element.'

        ALWAYS_NEW_LINE_MESSAGE = 'Closing hash brace must be on the line ' \
                                  'after the last hash element.'

        ALWAYS_SAME_LINE_MESSAGE = 'Closing hash brace must be on the same ' \
                                   'line as the last hash element.'

        def on_hash(node)
          check_brace_layout(node)
        end
      end
    end
  end
end
