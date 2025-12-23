# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks whether the multiline do end blocks have a newline
      # after the start of the block. Additionally, it checks whether the block
      # arguments, if any, are on the same line as the start of the
      # block. Putting block arguments on separate lines, because the whole
      # line would otherwise be too long, is accepted.
      #
      # @example
      #   # bad
      #   blah do |i| foo(i)
      #     bar(i)
      #   end
      #
      #   # bad
      #   blah do
      #     |i| foo(i)
      #     bar(i)
      #   end
      #
      #   # good
      #   blah do |i|
      #     foo(i)
      #     bar(i)
      #   end
      #
      #   # bad
      #   blah { |i| foo(i)
      #     bar(i)
      #   }
      #
      #   # good
      #   blah { |i|
      #     foo(i)
      #     bar(i)
      #   }
      #
      #   # good
      #   blah { |
      #     long_list,
      #     of_parameters,
      #     that_would_not,
      #     fit_on_one_line
      #   |
      #     foo(i)
      #     bar(i)
      #   }
      class MultilineBlockLayout < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Block body expression is on the same line as the block start.'
        ARG_MSG = 'Block argument expression is not on the same line as the block start.'
        PIPE_SIZE = '|'.length

        def on_block(node)
          return if node.single_line?

          unless args_on_beginning_line?(node) || line_break_necessary_in_args?(node)
            add_offense_for_expression(node, node.arguments, ARG_MSG)
          end

          return unless node.body && same_line?(node.loc.begin, node.body)

          add_offense_for_expression(node, node.body, MSG)
        end

        alias on_numblock on_block
        alias on_itblock on_block

        private

        def args_on_beginning_line?(node)
          !node.arguments? || node.loc.begin.line == node.arguments.loc.last_line
        end

        def line_break_necessary_in_args?(node)
          needed_length_for_args(node) > max_line_length
        end

        def needed_length_for_args(node)
          node.source_range.column +
            characters_needed_for_space_and_pipes(node) +
            node.source.lines.first.chomp.length +
            block_arg_string(node, node.arguments).length
        end

        def characters_needed_for_space_and_pipes(node)
          if node.source.lines.first.end_with?("|\n")
            PIPE_SIZE
          else
            (PIPE_SIZE * 2) + 1
          end
        end

        def add_offense_for_expression(node, expr, msg)
          expression = expr.source_range
          range = range_between(expression.begin_pos, expression.end_pos)

          add_offense(range, message: msg) { |corrector| autocorrect(corrector, node) }
        end

        def autocorrect(corrector, node)
          unless args_on_beginning_line?(node)
            autocorrect_arguments(corrector, node)
            expr_before_body = node.arguments.source_range.end
          end

          return unless node.body

          expr_before_body ||= node.loc.begin

          return unless same_line?(expr_before_body, node.body)

          autocorrect_body(corrector, node, node.body)
        end

        def autocorrect_arguments(corrector, node)
          end_pos = range_with_surrounding_space(
            node.arguments.source_range,
            side: :right,
            newlines: false
          ).end_pos
          range = range_between(node.loc.begin.end.begin_pos, end_pos)
          corrector.replace(range, " |#{block_arg_string(node, node.arguments)}|")
        end

        def autocorrect_body(corrector, node, block_body)
          first_node = if block_body.begin_type? && !block_body.source.start_with?('(')
                         block_body.children.first
                       else
                         block_body
                       end

          block_start_col = node.source_range.column

          corrector.insert_before(first_node, "\n  #{' ' * block_start_col}")
        end

        def block_arg_string(node, args)
          arg_string = args.children.map do |arg|
            if arg.mlhs_type?
              "(#{block_arg_string(node, arg)})"
            else
              arg.source
            end
          end.join(', ')
          arg_string += ',' if include_trailing_comma?(node.arguments)
          arg_string
        end

        def include_trailing_comma?(args)
          arg_count = args.each_descendant(:arg).to_a.size
          arg_count == 1 && args.source.include?(',')
        end
      end
    end
  end
end
