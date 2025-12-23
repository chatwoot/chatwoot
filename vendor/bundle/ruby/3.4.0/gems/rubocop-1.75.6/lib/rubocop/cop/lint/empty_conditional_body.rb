# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for the presence of `if`, `elsif` and `unless` branches without a body.
      #
      # NOTE: empty `else` branches are handled by `Style/EmptyElse`.
      #
      # @example
      #   # bad
      #   if condition
      #   end
      #
      #   # bad
      #   unless condition
      #   end
      #
      #   # bad
      #   if condition
      #     do_something
      #   elsif other_condition
      #   end
      #
      #   # good
      #   if condition
      #     do_something
      #   end
      #
      #   # good
      #   unless condition
      #     do_something
      #   end
      #
      #   # good
      #   if condition
      #     do_something
      #   elsif other_condition
      #     nil
      #   end
      #
      #   # good
      #   if condition
      #     do_something
      #   elsif other_condition
      #     do_something_else
      #   end
      #
      # @example AllowComments: true (default)
      #   # good
      #   if condition
      #     do_something
      #   elsif other_condition
      #     # noop
      #   end
      #
      # @example AllowComments: false
      #   # bad
      #   if condition
      #     do_something
      #   elsif other_condition
      #     # noop
      #   end
      #
      class EmptyConditionalBody < Base
        extend AutoCorrector
        include CommentsHelp

        MSG = 'Avoid `%<keyword>s` branches without a body.'

        def on_if(node)
          return if node.body || same_line?(node.loc.begin, node.loc.end)
          return if cop_config['AllowComments'] && contains_comments?(node)

          range = offense_range(node)

          add_offense(range, message: format(MSG, keyword: node.keyword)) do |corrector|
            next unless can_simplify_conditional?(node)

            flip_orphaned_else(corrector, node)
          end
        end

        private

        def offense_range(node)
          if node.loc.else
            node.source_range.begin.join(node.loc.else.begin)
          else
            node.source_range
          end
        end

        def can_simplify_conditional?(node)
          node.else_branch && node.loc.else.source == 'else'
        end

        def remove_empty_branch(corrector, node)
          range = if empty_if_branch?(node) && else_branch?(node)
                    branch_range(node)
                  else
                    deletion_range(branch_range(node))
                  end

          corrector.remove(range)
        end

        def flip_orphaned_else(corrector, node)
          corrector.replace(node.loc.else, "#{node.inverse_keyword} #{node.condition.source}")
          remove_empty_branch(corrector, node)
        end

        def empty_if_branch?(node)
          return false unless (parent = node.parent)
          return true unless parent.if_type?
          return true unless (if_branch = parent.if_branch)

          if_branch.if_type? && !if_branch.body
        end

        def else_branch?(node)
          node.else_branch && !node.else_branch.if_type?
        end

        def branch_range(node)
          if empty_if_branch?(node) && else_branch?(node)
            node.source_range.with(end_pos: node.loc.else.begin_pos)
          elsif node.loc.else
            node.source_range.with(end_pos: node.condition.source_range.end_pos)
          end
        end

        def deletion_range(range)
          # Collect a range between the start of the `if` node and the next relevant node,
          # including final new line.
          # Based on `RangeHelp#range_by_whole_lines` but allows the `if` to not start
          # on the first column.
          buffer = @processed_source.buffer

          last_line = buffer.source_line(range.last_line)
          end_offset = last_line.length - range.last_column + 1

          range.adjust(end_pos: end_offset).intersect(buffer.source_range)
        end
      end
    end
  end
end
