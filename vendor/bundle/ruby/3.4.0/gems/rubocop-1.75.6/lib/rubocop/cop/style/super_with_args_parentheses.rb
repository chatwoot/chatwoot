# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the presence of parentheses in `super` containing arguments.
      #
      # `super` is a keyword and is provided as a distinct cop from those designed for method call.
      #
      # @example
      #
      #   # bad
      #   super name, age
      #
      #   # good
      #   super(name, age)
      #
      class SuperWithArgsParentheses < Base
        extend AutoCorrector

        MSG = 'Use parentheses for `super` with arguments.'

        def on_super(node)
          return if node.parenthesized?

          add_offense(node) do |corrector|
            range = node.loc.keyword.end.join(node.first_argument.source_range.begin)
            corrector.replace(range, '(')
            corrector.insert_after(node.last_argument, ')')
          end
        end
      end
    end
  end
end
