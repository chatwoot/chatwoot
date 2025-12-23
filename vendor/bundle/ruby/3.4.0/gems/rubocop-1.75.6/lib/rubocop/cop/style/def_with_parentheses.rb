# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for parentheses in the definition of a method,
      # that does not take any arguments. Both instance and
      # class/singleton methods are checked.
      #
      # @example
      #
      #   # bad
      #   def foo()
      #     do_something
      #   end
      #
      #   # good
      #   def foo
      #     do_something
      #   end
      #
      #   # bad
      #   def foo() = do_something
      #
      #   # good
      #   def foo = do_something
      #
      #   # good (without parentheses it's a syntax error)
      #   def foo() do_something end
      #
      #   # bad
      #   def Baz.foo()
      #     do_something
      #   end
      #
      #   # good
      #   def Baz.foo
      #     do_something
      #   end
      class DefWithParentheses < Base
        extend AutoCorrector

        MSG = "Omit the parentheses in defs when the method doesn't accept any arguments."

        def on_def(node)
          return if node.single_line? && !node.endless?
          return unless !node.arguments? && (node_arguments = node.arguments.source_range)

          add_offense(node_arguments) do |corrector|
            corrector.remove(node_arguments)
          end
        end
        alias on_defs on_def
      end
    end
  end
end
