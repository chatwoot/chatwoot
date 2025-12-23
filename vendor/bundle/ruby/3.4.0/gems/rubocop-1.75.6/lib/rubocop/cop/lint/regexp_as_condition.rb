# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for regexp literals used as `match-current-line`.
      # If a regexp literal is in condition, the regexp matches `$_` implicitly.
      #
      # @example
      #   # bad
      #   if /foo/
      #     do_something
      #   end
      #
      #   # good
      #   if /foo/ =~ $_
      #     do_something
      #   end
      class RegexpAsCondition < Base
        extend AutoCorrector

        MSG = 'Do not use regexp literal as a condition. ' \
              'The regexp literal matches `$_` implicitly.'

        def on_match_current_line(node)
          return if node.ancestors.none?(&:conditional?)
          return if part_of_ignored_node?(node)

          add_offense(node) { |corrector| corrector.replace(node, "#{node.source} =~ $_") }

          ignore_node(node)
        end
      end
    end
  end
end
