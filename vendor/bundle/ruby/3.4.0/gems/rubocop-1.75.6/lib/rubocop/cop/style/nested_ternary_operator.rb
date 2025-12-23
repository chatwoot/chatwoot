# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for nested ternary op expressions.
      #
      # @example
      #   # bad
      #   a ? (b ? b1 : b2) : a2
      #
      #   # good
      #   if a
      #     b ? b1 : b2
      #   else
      #     a2
      #   end
      class NestedTernaryOperator < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Ternary operators must not be nested. Prefer `if` or `else` constructs instead.'

        def on_if(node)
          return unless node.ternary?

          node.each_descendant(:if).select(&:ternary?).each do |nested_ternary|
            add_offense(nested_ternary) do |corrector|
              next if part_of_ignored_node?(node)

              autocorrect(corrector, node)
              ignore_node(node)
            end
          end
        end

        private

        def autocorrect(corrector, if_node)
          replace_loc_and_whitespace(corrector, if_node.loc.question, "\n")
          replace_loc_and_whitespace(corrector, if_node.loc.colon, "\nelse\n")
          corrector.replace(if_node.if_branch, remove_parentheses(if_node.if_branch.source))
          corrector.wrap(if_node, 'if ', "\nend")
        end

        def remove_parentheses(source)
          if source.start_with?('(') && source.end_with?(')')
            source.delete_prefix('(').delete_suffix(')')
          else
            source
          end
        end

        def replace_loc_and_whitespace(corrector, range, replacement)
          corrector.replace(
            range_with_surrounding_space(range: range, whitespace: true),
            replacement
          )
        end
      end
    end
  end
end
