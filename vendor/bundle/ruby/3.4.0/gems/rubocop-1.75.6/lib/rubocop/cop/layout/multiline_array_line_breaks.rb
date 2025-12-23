# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Ensures that each item in a multi-line array
      # starts on a separate line.
      #
      # @example
      #
      #   # bad
      #   [
      #     a, b,
      #     c
      #   ]
      #
      #   # good
      #   [
      #     a,
      #     b,
      #     c
      #   ]
      #
      #   # good
      #   [
      #     a,
      #     b,
      #     foo(
      #       bar
      #     )
      #   ]
      #
      # @example AllowMultilineFinalElement: false (default)
      #
      #   # bad
      #   [a, b, foo(
      #     bar
      #   )]
      #
      # @example AllowMultilineFinalElement: true
      #
      #   # good
      #   [a, b, foo(
      #     bar
      #   )]
      #
      class MultilineArrayLineBreaks < Base
        include MultilineElementLineBreaks
        extend AutoCorrector

        MSG = 'Each item in a multi-line array must start on a separate line.'

        def on_array(node)
          check_line_breaks(node, node.children, ignore_last: ignore_last_element?)
        end

        private

        def ignore_last_element?
          !!cop_config['AllowMultilineFinalElement']
        end
      end
    end
  end
end
