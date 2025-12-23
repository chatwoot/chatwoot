# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for a line break before the first argument in a
      # multi-line method call.
      #
      # @example
      #
      #   # bad
      #   method(foo, bar,
      #     baz)
      #
      #   # good
      #   method(
      #     foo, bar,
      #     baz)
      #
      #     # ignored
      #     method foo, bar,
      #       baz
      #
      # @example AllowMultilineFinalElement: false (default)
      #
      #   # bad
      #   method(foo, bar, {
      #     baz: "a",
      #     qux: "b",
      #   })
      #
      #   # good
      #   method(
      #     foo, bar, {
      #     baz: "a",
      #     qux: "b",
      #   })
      #
      # @example AllowMultilineFinalElement: true
      #
      #   # bad
      #   method(foo,
      #     bar,
      #     {
      #       baz: "a",
      #       qux: "b",
      #     }
      #   )
      #
      #   # good
      #   method(foo, bar, {
      #     baz: "a",
      #     qux: "b",
      #   })
      #
      #   # good
      #   method(
      #     foo,
      #     bar,
      #     {
      #       baz: "a",
      #       qux: "b",
      #     }
      #   )
      #
      # @example AllowedMethods: ['some_method']
      #
      #   # good
      #   some_method(foo, bar,
      #     baz)
      class FirstMethodArgumentLineBreak < Base
        include FirstElementLineBreak
        include AllowedMethods
        extend AutoCorrector

        MSG = 'Add a line break before the first argument of a multi-line method argument list.'

        def on_send(node)
          return if allowed_method?(node.method_name)

          args = node.arguments.dup

          # If there is a trailing hash arg without explicit braces, like this:
          #
          #    method(1, 'key1' => value1, 'key2' => value2)
          #
          # ...then each key/value pair is treated as a method 'argument'
          # when determining where line breaks should appear.
          last_arg = args.last
          args.concat(args.pop.children) if last_arg&.hash_type? && !last_arg&.braces?

          check_method_line_break(node, args, ignore_last: ignore_last_element?)
        end
        alias on_csend on_send
        alias on_super on_send

        private

        def ignore_last_element?
          !!cop_config['AllowMultilineFinalElement']
        end
      end
    end
  end
end
