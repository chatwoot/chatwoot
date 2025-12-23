# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for trailing comma in hash literals.
      # The configuration options are:
      #
      # * `consistent_comma`: Requires a comma after the last item of all non-empty, multiline hash
      # literals.
      # * `comma`: Requires a comma after the last item in a hash, but only when each item is on its
      # own line.
      # * `diff_comma`: Requires a comma after the last item in a hash, but only when that item is
      # followed by an immediate newline, even if there is an inline comment on the same line.
      # * `no_comma`: Does not require a comma after the last item in a hash
      #
      # @example EnforcedStyleForMultiline: consistent_comma
      #
      #   # bad
      #   a = { foo: 1, bar: 2, }
      #
      #   # good
      #   a = { foo: 1, bar: 2 }
      #
      #   # good
      #   a = {
      #     foo: 1, bar: 2,
      #     qux: 3,
      #   }
      #
      #   # good
      #   a = {
      #     foo: 1, bar: 2, qux: 3,
      #   }
      #
      #   # good
      #   a = {
      #     foo: 1,
      #     bar: 2,
      #   }
      #
      #   # bad
      #   a = { foo: 1, bar: 2,
      #         baz: 3, qux: 4 }
      #
      #   # good
      #   a = { foo: 1, bar: 2,
      #         baz: 3, qux: 4, }
      #
      # @example EnforcedStyleForMultiline: comma
      #
      #   # bad
      #   a = { foo: 1, bar: 2, }
      #
      #   # good
      #   a = { foo: 1, bar: 2 }
      #
      #   # bad
      #   a = {
      #     foo: 1, bar: 2,
      #     qux: 3,
      #   }
      #
      #   # good
      #   a = {
      #     foo: 1, bar: 2,
      #     qux: 3
      #   }
      #
      #   # bad
      #   a = {
      #     foo: 1, bar: 2, qux: 3,
      #   }
      #
      #   # good
      #   a = {
      #     foo: 1, bar: 2, qux: 3
      #   }
      #
      #   # good
      #   a = {
      #     foo: 1,
      #     bar: 2,
      #   }
      #
      # @example EnforcedStyleForMultiline: diff_comma
      #
      #   # bad
      #   a = { foo: 1, bar: 2, }
      #
      #   # good
      #   a = { foo: 1, bar: 2 }
      #
      #   # good
      #   a = {
      #     foo: 1, bar: 2,
      #     qux: 3,
      #   }
      #
      #   # good
      #   a = {
      #     foo: 1, bar: 2, qux: 3,
      #   }
      #
      #   # good
      #   a = {
      #     foo: 1,
      #     bar: 2,
      #   }
      #
      #   # bad
      #   a = { foo: 1, bar: 2,
      #         baz: 3, qux: 4, }
      #
      #   # good
      #   a = { foo: 1, bar: 2,
      #         baz: 3, qux: 4 }
      #
      # @example EnforcedStyleForMultiline: no_comma (default)
      #
      #   # bad
      #   a = { foo: 1, bar: 2, }
      #
      #   # good
      #   a = {
      #     foo: 1,
      #     bar: 2
      #   }
      class TrailingCommaInHashLiteral < Base
        include TrailingComma
        extend AutoCorrector

        def on_hash(node)
          check_literal(node, 'item of %<article>s hash')
        end
      end
    end
  end
end
