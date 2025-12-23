# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks that the closing brace in a method definition is either
      # on the same line as the last method parameter, or a new line.
      #
      # When using the `symmetrical` (default) style:
      #
      # If a method definition's opening brace is on the same line as the
      # first parameter of the definition, then the closing brace should be
      # on the same line as the last parameter of the definition.
      #
      # If a method definition's opening brace is on the line above the first
      # parameter of the definition, then the closing brace should be on the
      # line below the last parameter of the definition.
      #
      # When using the `new_line` style:
      #
      # The closing brace of a multi-line method definition must be on the line
      # after the last parameter of the definition.
      #
      # When using the `same_line` style:
      #
      # The closing brace of a multi-line method definition must be on the same
      # line as the last parameter of the definition.
      #
      # @example EnforcedStyle: symmetrical (default)
      #   # bad
      #   def foo(a,
      #     b
      #   )
      #   end
      #
      #   # bad
      #   def foo(
      #     a,
      #     b)
      #   end
      #
      #   # good
      #   def foo(a,
      #     b)
      #   end
      #
      #   # good
      #   def foo(
      #     a,
      #     b
      #   )
      #   end
      #
      # @example EnforcedStyle: new_line
      #   # bad
      #   def foo(
      #     a,
      #     b)
      #   end
      #
      #   # bad
      #   def foo(a,
      #     b)
      #   end
      #
      #   # good
      #   def foo(a,
      #     b
      #   )
      #   end
      #
      #   # good
      #   def foo(
      #     a,
      #     b
      #   )
      #   end
      #
      # @example EnforcedStyle: same_line
      #   # bad
      #   def foo(a,
      #     b
      #   )
      #   end
      #
      #   # bad
      #   def foo(
      #     a,
      #     b
      #   )
      #   end
      #
      #   # good
      #   def foo(
      #     a,
      #     b)
      #   end
      #
      #   # good
      #   def foo(a,
      #     b)
      #   end
      class MultilineMethodDefinitionBraceLayout < Base
        include MultilineLiteralBraceLayout
        extend AutoCorrector

        SAME_LINE_MESSAGE = 'Closing method definition brace must be on the ' \
                            'same line as the last parameter when opening brace is on the same ' \
                            'line as the first parameter.'

        NEW_LINE_MESSAGE = 'Closing method definition brace must be on the ' \
                           'line after the last parameter when opening brace is on a separate ' \
                           'line from the first parameter.'

        ALWAYS_NEW_LINE_MESSAGE = 'Closing method definition brace must be ' \
                                  'on the line after the last parameter.'

        ALWAYS_SAME_LINE_MESSAGE = 'Closing method definition brace must be ' \
                                   'on the same line as the last parameter.'

        def on_def(node)
          check_brace_layout(node.arguments)
        end
        alias on_defs on_def
      end
    end
  end
end
