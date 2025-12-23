# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for trailing code after the method definition.
      #
      # @example
      #   # bad
      #   def some_method
      #   do_stuff; end
      #
      #   def do_this(x)
      #     baz.map { |b| b.this(x) } end
      #
      #   def foo
      #     block do
      #       bar
      #     end end
      #
      #   # good
      #   def some_method
      #     do_stuff
      #   end
      #
      #   def do_this(x)
      #     baz.map { |b| b.this(x) }
      #   end
      #
      #   def foo
      #     block do
      #       bar
      #     end
      #   end
      #
      class TrailingMethodEndStatement < Base
        extend AutoCorrector

        MSG = 'Place the end statement of a multi-line method on its own line.'

        def on_def(node)
          return if node.endless? || !trailing_end?(node)

          add_offense(node.loc.end) do |corrector|
            corrector.insert_before(node.loc.end, "\n#{' ' * node.loc.keyword.column}")
          end
        end

        private

        def trailing_end?(node)
          node.body && node.multiline? && body_and_end_on_same_line?(node)
        end

        def body_and_end_on_same_line?(node)
          last_child = node.children.last
          last_child.loc.last_line == node.loc.end.last_line
        end
      end
    end
  end
end
