# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks that the closing brace in a method call is either
      # on the same line as the last method argument, or a new line.
      #
      # When using the `symmetrical` (default) style:
      #
      # If a method call's opening brace is on the same line as the first
      # argument of the call, then the closing brace should be on the same
      # line as the last argument of the call.
      #
      # If a method call's opening brace is on the line above the first
      # argument of the call, then the closing brace should be on the line
      # below the last argument of the call.
      #
      # When using the `new_line` style:
      #
      # The closing brace of a multi-line method call must be on the line
      # after the last argument of the call.
      #
      # When using the `same_line` style:
      #
      # The closing brace of a multi-line method call must be on the same
      # line as the last argument of the call.
      #
      # @example EnforcedStyle: symmetrical (default)
      #   # bad
      #   foo(a,
      #     b
      #   )
      #
      #   # bad
      #   foo(
      #     a,
      #     b)
      #
      #   # good
      #   foo(a,
      #     b)
      #
      #   # good
      #   foo(
      #     a,
      #     b
      #   )
      #
      # @example EnforcedStyle: new_line
      #   # bad
      #   foo(
      #     a,
      #     b)
      #
      #   # bad
      #   foo(a,
      #     b)
      #
      #   # good
      #   foo(a,
      #     b
      #   )
      #
      #   # good
      #   foo(
      #     a,
      #     b
      #   )
      #
      # @example EnforcedStyle: same_line
      #   # bad
      #   foo(a,
      #     b
      #   )
      #
      #   # bad
      #   foo(
      #     a,
      #     b
      #   )
      #
      #   # good
      #   foo(
      #     a,
      #     b)
      #
      #   # good
      #   foo(a,
      #     b)
      class MultilineMethodCallBraceLayout < Base
        include MultilineLiteralBraceLayout
        extend AutoCorrector

        SAME_LINE_MESSAGE = 'Closing method call brace must be on the ' \
                            'same line as the last argument when opening brace is on the same ' \
                            'line as the first argument.'

        NEW_LINE_MESSAGE = 'Closing method call brace must be on the ' \
                           'line after the last argument when opening brace is on a separate ' \
                           'line from the first argument.'

        ALWAYS_NEW_LINE_MESSAGE = 'Closing method call brace must be on ' \
                                  'the line after the last argument.'

        ALWAYS_SAME_LINE_MESSAGE = 'Closing method call brace must be on ' \
                                   'the same line as the last argument.'

        def on_send(node)
          check_brace_layout(node)
        end
        alias on_csend on_send

        private

        def children(node)
          node.arguments
        end

        def ignored_literal?(node)
          single_line_ignoring_receiver?(node) || super
        end

        def single_line_ignoring_receiver?(node)
          return false unless node.loc.begin && node.loc.end

          node.loc.begin.line == node.loc.end.line
        end
      end
    end
  end
end
