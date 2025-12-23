# frozen_string_literal: true

module RuboCop
  module Cop
    # This autocorrects parentheses
    class ParenthesesCorrector
      class << self
        include RangeHelp

        COMMA_REGEXP = /(?<=\))\s*,/.freeze

        def correct(corrector, node)
          corrector.remove(node.loc.begin)
          corrector.remove(node.loc.end)
          handle_orphaned_comma(corrector, node)

          return unless ternary_condition?(node) && next_char_is_question_mark?(node)

          corrector.insert_after(node.loc.end, ' ')
        end

        private

        def ternary_condition?(node)
          node.parent&.if_type? && node.parent.ternary?
        end

        def next_char_is_question_mark?(node)
          node.loc.last_column == node.parent.loc.question.column
        end

        def only_closing_paren_before_comma?(node)
          source_buffer = node.source_range.source_buffer
          line_range = source_buffer.line_range(node.loc.end.line)

          line_range.source.start_with?(/\s*\)\s*,/)
        end

        # If removing parentheses leaves a comma on its own line, remove all the whitespace
        # preceding it to prevent a syntax error.
        def handle_orphaned_comma(corrector, node)
          return unless only_closing_paren_before_comma?(node)

          range = extend_range_for_heredoc(node, parens_range(node))
          corrector.remove(range)

          add_heredoc_comma(corrector, node)
        end

        # Get a range for the closing parenthesis and all whitespace to the left of it
        def parens_range(node)
          range_with_surrounding_space(
            range: node.loc.end,
            buffer: node.source_range.source_buffer,
            side: :left,
            newlines: true,
            whitespace: true,
            continuations: true
          )
        end

        # If the node contains a heredoc, remove the comma too
        # It'll be added back in the right place later
        def extend_range_for_heredoc(node, range)
          return range unless heredoc?(node)

          comma_line = range_by_whole_lines(node.loc.end, buffer: node.source_range.source_buffer)
          offset = comma_line.source.match(COMMA_REGEXP)[0]&.size || 0

          range.adjust(end_pos: offset)
        end

        # Add a comma back after the heredoc identifier
        def add_heredoc_comma(corrector, node)
          return unless heredoc?(node)

          corrector.insert_after(node.child_nodes.last, ',')
        end

        def heredoc?(node)
          node.child_nodes.last.loc.is_a?(Parser::Source::Map::Heredoc)
        end
      end
    end
  end
end
