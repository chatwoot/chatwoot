# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Ensures that each key in a multi-line hash
      # starts on a separate line.
      #
      # @example
      #
      #   # bad
      #   {
      #     a: 1, b: 2,
      #     c: 3
      #   }
      #
      #   # good
      #   {
      #     a: 1,
      #     b: 2,
      #     c: 3
      #   }
      #
      #   # good
      #   {
      #     a: 1,
      #     b: {
      #       c: 3,
      #     }
      #   }
      #
      # @example AllowMultilineFinalElement: false (default)
      #
      #   # bad
      #   { a: 1, b: {
      #     c: 3,
      #   }}
      #
      # @example AllowMultilineFinalElement: true
      #
      #   # good
      #   { a: 1, b: {
      #     c: 3,
      #   }}
      #
      class MultilineHashKeyLineBreaks < Base
        include MultilineElementLineBreaks
        extend AutoCorrector

        MSG = 'Each key in a multi-line hash must start on a separate line.'

        def on_hash(node)
          # This cop only deals with hashes wrapped by a set of curly
          # braces like {foo: 1}. That is, not a kwargs hashes.
          # Layout/MultilineMethodArgumentLineBreaks handles those.
          return unless starts_with_curly_brace?(node)
          return unless node.loc.begin

          check_line_breaks(node, node.children, ignore_last: ignore_last_element?)
        end

        private

        def starts_with_curly_brace?(node)
          node.loc.begin
        end

        def ignore_last_element?
          !!cop_config['AllowMultilineFinalElement']
        end
      end
    end
  end
end
