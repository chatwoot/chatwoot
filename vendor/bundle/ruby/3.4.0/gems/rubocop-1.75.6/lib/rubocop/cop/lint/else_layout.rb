# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for odd `else` block layout - like
      # having an expression on the same line as the `else` keyword,
      # which is usually a mistake.
      #
      # Its autocorrection tweaks layout to keep the syntax. So, this autocorrection
      # is compatible correction for bad case syntax, but if your code makes a mistake
      # with `elsif` and `else`, you will have to correct it manually.
      #
      # @example
      #
      #   # bad
      #
      #   if something
      #     # ...
      #   else do_this
      #     do_that
      #   end
      #
      #   # good
      #
      #   # This code is compatible with the bad case. It will be autocorrected like this.
      #   if something
      #     # ...
      #   else
      #     do_this
      #     do_that
      #   end
      #
      #   # This code is incompatible with the bad case.
      #   # If `do_this` is a condition, `elsif` should be used instead of `else`.
      #   if something
      #     # ...
      #   elsif do_this
      #     do_that
      #   end
      class ElseLayout < Base
        include Alignment
        include RangeHelp
        extend AutoCorrector

        MSG = 'Odd `else` layout detected. Did you mean to use `elsif`?'

        def on_if(node)
          return if node.ternary?

          # If the if is on a single line, it'll be handled by `Style/OneLineConditional`
          return if node.single_line?

          check(node)
        end

        private

        def check(node)
          return unless node.else_branch

          if node.else? && node.loc.else.is?('else')
            check_else(node)
          elsif node.if?
            check(node.else_branch)
          end
        end

        def check_else(node)
          else_branch = node.else_branch
          first_else = else_branch.begin_type? ? else_branch.children.first : else_branch

          return unless first_else
          return unless same_line?(first_else, node.loc.else)

          add_offense(first_else) { |corrector| autocorrect(corrector, node, first_else) }
        end

        def autocorrect(corrector, node, first_else)
          corrector.insert_after(node.loc.else, "\n")

          blank_range = range_between(node.loc.else.end_pos, first_else.source_range.begin_pos)
          corrector.replace(blank_range, indentation(node))
        end
      end
    end
  end
end
