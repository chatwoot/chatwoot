# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the indentation of hanging closing parentheses in
      # method calls, method definitions, and grouped expressions. A hanging
      # closing parenthesis means `)` preceded by a line break.
      #
      # @example
      #
      #   # bad
      #   some_method(
      #     a,
      #     b
      #     )
      #
      #   some_method(
      #     a, b
      #     )
      #
      #   some_method(a, b, c
      #     )
      #
      #   some_method(a,
      #               b,
      #               c
      #     )
      #
      #   some_method(a,
      #     x: 1,
      #     y: 2
      #     )
      #
      #   # Scenario 1: When First Parameter Is On Its Own Line
      #
      #   # good: when first param is on a new line, right paren is *always*
      #   #       outdented by IndentationWidth
      #   some_method(
      #     a,
      #     b
      #   )
      #
      #   # good
      #   some_method(
      #     a, b
      #   )
      #
      #   # Scenario 2: When First Parameter Is On The Same Line
      #
      #   # good: when all other params are also on the same line, outdent
      #   #       right paren by IndentationWidth
      #   some_method(a, b, c
      #              )
      #
      #   # good: when all other params are on multiple lines, but are lined
      #   #       up, align right paren with left paren
      #   some_method(a,
      #               b,
      #               c
      #              )
      #
      #   # good: when other params are not lined up on multiple lines, outdent
      #   #       right paren by IndentationWidth
      #   some_method(a,
      #     x: 1,
      #     y: 2
      #   )
      #
      #
      class ClosingParenthesisIndentation < Base
        include Alignment
        extend AutoCorrector

        MSG_INDENT = 'Indent `)` to column %<expected>d (not %<actual>d)'

        MSG_ALIGN = 'Align `)` with `(`.'

        def on_send(node)
          check(node, node.arguments)
        end
        alias on_csend on_send

        def on_begin(node)
          check(node, node.children)
        end

        def on_def(node)
          check(node.arguments, node.arguments)
        end
        alias on_defs on_def

        private

        def autocorrect(corrector, node)
          AlignmentCorrector.correct(corrector, processed_source, node, @column_delta)
        end

        def check(node, elements)
          if elements.empty?
            check_for_no_elements(node)
          else
            check_for_elements(node, elements)
          end
        end

        def check_for_elements(node, elements)
          left_paren  = node.loc.begin
          right_paren = node.loc.end

          return unless right_paren && begins_its_line?(right_paren)

          correct_column = expected_column(left_paren, elements)

          @column_delta = correct_column - right_paren.column

          return if @column_delta.zero?

          message = message(correct_column, left_paren, right_paren)
          add_offense(right_paren, message: message) do |corrector|
            autocorrect(corrector, right_paren)
          end
        end

        def check_for_no_elements(node)
          left_paren = node.loc.begin
          right_paren = node.loc.end
          return unless right_paren && begins_its_line?(right_paren)

          candidates = correct_column_candidates(node, left_paren)

          return if candidates.include?(right_paren.column)

          # Although there are multiple choices for a correct column,
          # select the first one of candidates to determine a specification.
          correct_column = candidates.first
          @column_delta = correct_column - right_paren.column
          message = message(correct_column, left_paren, right_paren)
          add_offense(right_paren, message: message) do |corrector|
            autocorrect(corrector, right_paren)
          end
        end

        def expected_column(left_paren, elements)
          if line_break_after_left_paren?(left_paren, elements)
            source_indent = processed_source.line_indentation(first_argument_line(elements))
            new_indent    = source_indent - configured_indentation_width

            new_indent.negative? ? 0 : new_indent
          elsif all_elements_aligned?(elements)
            left_paren.column
          else
            processed_source.line_indentation(first_argument_line(elements))
          end
        end

        def all_elements_aligned?(elements)
          if elements.first.hash_type?
            elements.first.each_child_node.map { |child| child.loc.column }
          else
            elements.flat_map do |e|
              e.loc.column
            end
          end.uniq.count == 1
        end

        def first_argument_line(elements)
          elements.first.loc.first_line
        end

        def correct_column_candidates(node, left_paren)
          [
            processed_source.line_indentation(left_paren.line),
            left_paren.column,
            node.loc.column
          ]
        end

        def message(correct_column, left_paren, right_paren)
          if correct_column == left_paren.column
            MSG_ALIGN
          else
            format(MSG_INDENT, expected: correct_column, actual: right_paren.column)
          end
        end

        def line_break_after_left_paren?(left_paren, elements)
          elements.first && elements.first.loc.line > left_paren.line
        end
      end
    end
  end
end
