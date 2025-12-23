# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks that a range literal is enclosed in parentheses when the end of the range is
      # at a line break.
      #
      # NOTE: The following is maybe intended for `(42..)`. But, compatible is `42..do_something`.
      # So, this cop does not provide autocorrection because it is left to user.
      #
      # [source,ruby]
      # ----
      # case condition
      # when 42..
      #   do_something
      # end
      # ----
      #
      # @example
      #
      #   # bad - Represents `(1..42)`, not endless range.
      #   1..
      #   42
      #
      #   # good - It's incompatible, but your intentions when using endless range may be:
      #   (1..)
      #   42
      #
      #   # good
      #   1..42
      #
      #   # good
      #   (1..42)
      #
      #   # good
      #   (1..
      #   42)
      #
      class RequireRangeParentheses < Base
        MSG = 'Wrap the endless range literal `%<range>s` to avoid precedence ambiguity.'

        def on_irange(node)
          return if node.parent&.begin_type?
          return unless node.begin && node.end
          return if same_line?(node.begin, node.end)

          message = format(MSG, range: "#{node.begin.source}#{node.loc.operator.source}")

          add_offense(node, message: message)
        end

        alias on_erange on_irange
      end
    end
  end
end
