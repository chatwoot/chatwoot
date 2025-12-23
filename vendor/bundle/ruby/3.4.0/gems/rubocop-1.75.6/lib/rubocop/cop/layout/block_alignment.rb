# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks whether the end keywords are aligned properly for do
      # end blocks.
      #
      # Three modes are supported through the `EnforcedStyleAlignWith`
      # configuration parameter:
      #
      # `start_of_block` : the `end` shall be aligned with the
      # start of the line where the `do` appeared.
      #
      # `start_of_line` : the `end` shall be aligned with the
      # start of the line where the expression started.
      #
      # `either` (which is the default) : the `end` is allowed to be in either
      # location. The autocorrect will default to `start_of_line`.
      #
      # @example EnforcedStyleAlignWith: either (default)
      #   # bad
      #
      #   foo.bar
      #     .each do
      #       baz
      #         end
      #
      #   # good
      #
      #   foo.bar
      #     .each do
      #       baz
      #   end
      #
      # @example EnforcedStyleAlignWith: start_of_block
      #   # bad
      #
      #   foo.bar
      #     .each do
      #       baz
      #         end
      #
      #   # good
      #
      #   foo.bar
      #     .each do
      #       baz
      #     end
      #
      # @example EnforcedStyleAlignWith: start_of_line
      #   # bad
      #
      #   foo.bar
      #     .each do
      #       baz
      #         end
      #
      #   # good
      #
      #   foo.bar
      #     .each do
      #       baz
      #   end
      #
      class BlockAlignment < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG = '%<current>s is not aligned with %<prefer>s%<alt_prefer>s.'

        # @!method block_end_align_target?(node, child)
        def_node_matcher :block_end_align_target?, <<~PATTERN
          {assignment?
           any_def
           splat
           and
           or
           (send _ :<<  ...)
           (send equal?(%1) !:[] ...)}
        PATTERN

        def on_block(node)
          check_block_alignment(start_for_block_node(node), node)
        end

        alias on_numblock on_block
        alias on_itblock on_block

        def style_parameter_name
          'EnforcedStyleAlignWith'
        end

        private

        def block_end_align_target(node)
          lineage = [node, *node.ancestors]

          lineage.each_cons(2) do |current, parent|
            return current if end_align_target?(current, parent)
          end

          lineage.last
        end

        def end_align_target?(node, parent)
          disqualified_parent?(parent, node) || !block_end_align_target?(parent, node)
        end

        def disqualified_parent?(parent, node)
          parent&.loc && parent.first_line != node.first_line && !parent.masgn_type?
        end

        def check_block_alignment(start_node, block_node)
          end_loc = block_node.loc.end
          return unless begins_its_line?(end_loc)

          start_loc = start_node.source_range
          return unless start_loc.column != end_loc.column || style == :start_of_block

          do_source_line_column = compute_do_source_line_column(block_node, end_loc)
          return unless do_source_line_column

          register_offense(block_node, start_loc, end_loc, do_source_line_column)
        end

        def register_offense(block_node,
                             start_loc,
                             end_loc,
                             do_source_line_column)
          error_source_line_column = if style == :start_of_block
                                       do_source_line_column
                                     else
                                       loc_to_source_line_column(start_loc)
                                     end

          message = format_message(start_loc, end_loc, do_source_line_column,
                                   error_source_line_column)

          add_offense(end_loc, message: message) do |corrector|
            autocorrect(corrector, block_node)
          end
        end

        def autocorrect(corrector, node)
          ancestor_node = if style == :start_of_block
                            start_for_block_node(node)
                          else
                            start_for_line_node(node)
                          end
          start_col = compute_start_col(ancestor_node, node)
          loc_end = node.loc.end
          delta = start_col - loc_end.column

          if delta.positive?
            add_space_before(corrector, loc_end, delta)
          elsif delta.negative?
            remove_space_before(corrector, loc_end.begin_pos, -delta)
          end
        end

        def format_message(start_loc, end_loc, do_source_line_column,
                           error_source_line_column)
          format(
            MSG,
            current: format_source_line_column(loc_to_source_line_column(end_loc)),
            prefer: format_source_line_column(error_source_line_column),
            alt_prefer: alt_start_msg(start_loc, do_source_line_column)
          )
        end

        def start_for_block_node(block_node)
          # Which node should we align the 'end' with?
          start_node = block_end_align_target(block_node)

          find_lhs_node(start_node)
        end

        def start_for_line_node(block_node)
          start_node = start_for_block_node(block_node)

          start_node = start_node.each_ancestor.to_a.reverse.find do |node|
            same_line?(start_node, node)
          end || start_node

          find_lhs_node(start_node)
        end

        # In offense message, we want to show the assignment LHS rather than
        # the entire assignment.
        def find_lhs_node(node)
          node = node.lhs while node.type?(:op_asgn, :masgn)
          node
        end

        def compute_do_source_line_column(node, end_loc)
          do_loc = node.loc.begin # Actually it's either do or {.

          # We've found that "end" is not aligned with the start node (which
          # can be a block, a variable assignment, etc). But we also allow
          # the "end" to be aligned with the start of the line where the "do"
          # is, which is a style some people use in multi-line chains of
          # blocks.
          match = /\S.*/.match(do_loc.source_line)
          indentation_of_do_line = match.begin(0)
          return unless end_loc.column != indentation_of_do_line || style == :start_of_line

          {
            source: match[0],
            line: do_loc.line,
            column: indentation_of_do_line
          }
        end

        def loc_to_source_line_column(loc)
          {
            source: loc.source.lines.to_a.first.chomp,
            line: loc.line,
            column: loc.column
          }
        end

        def alt_start_msg(start_loc, source_line_column)
          if style != :either ||
             (start_loc.line == source_line_column[:line] &&
                 start_loc.column == source_line_column[:column])
            ''
          else
            " or #{format_source_line_column(source_line_column)}"
          end
        end

        def format_source_line_column(source_line_column)
          "`#{source_line_column[:source]}` at #{source_line_column[:line]}, " \
            "#{source_line_column[:column]}"
        end

        def compute_start_col(ancestor_node, node)
          if style == :start_of_block
            do_loc = node.loc.begin
            return do_loc.source_line =~ /\S/
          end
          (ancestor_node || node).source_range.column
        end

        def add_space_before(corrector, loc, delta)
          corrector.insert_before(loc, ' ' * delta)
        end

        def remove_space_before(corrector, end_pos, delta)
          range = range_between(end_pos - delta, end_pos)

          corrector.remove(range)
        end
      end
    end
  end
end
