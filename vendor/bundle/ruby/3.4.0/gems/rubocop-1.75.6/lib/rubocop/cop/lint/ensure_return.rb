# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for `return` from an `ensure` block.
      # `return` from an ensure block is a dangerous code smell as it
      # will take precedence over any exception being raised,
      # and the exception will be silently thrown away as if it were rescued.
      #
      # If you want to rescue some (or all) exceptions, best to do it explicitly
      #
      # @example
      #
      #   # bad
      #   def foo
      #     do_something
      #   ensure
      #     cleanup
      #     return self
      #   end
      #
      #   # good
      #   def foo
      #     do_something
      #     self
      #   ensure
      #     cleanup
      #   end
      #
      #   # good
      #   def foo
      #     begin
      #       do_something
      #     rescue SomeException
      #       # Let's ignore this exception
      #     end
      #     self
      #   ensure
      #     cleanup
      #   end
      class EnsureReturn < Base
        MSG = 'Do not return from an `ensure` block.'

        def on_ensure(node)
          node.branch&.each_node(:return) { |return_node| add_offense(return_node) }
        end
      end
    end
  end
end
