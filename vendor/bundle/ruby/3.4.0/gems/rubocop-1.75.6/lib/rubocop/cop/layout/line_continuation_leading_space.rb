# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks that strings broken over multiple lines (by a backslash) contain
      # trailing spaces instead of leading spaces (default) or leading spaces
      # instead of trailing spaces.
      #
      # @example EnforcedStyle: trailing (default)
      #   # bad
      #   'this text contains a lot of' \
      #   '               spaces'
      #
      #   # good
      #   'this text contains a lot of               ' \
      #   'spaces'
      #
      #   # bad
      #   'this text is too' \
      #   ' long'
      #
      #   # good
      #   'this text is too ' \
      #   'long'
      #
      # @example EnforcedStyle: leading
      #   # bad
      #   'this text contains a lot of               ' \
      #   'spaces'
      #
      #   # good
      #   'this text contains a lot of' \
      #   '               spaces'
      #
      #   # bad
      #   'this text is too ' \
      #   'long'
      #
      #   # good
      #   'this text is too' \
      #   ' long'
      class LineContinuationLeadingSpace < Base
        include RangeHelp
        extend AutoCorrector

        LINE_1_ENDING = /['"]\s*\\\n/.freeze
        LINE_2_BEGINNING = /\A\s*['"]/.freeze
        LEADING_STYLE_OFFENSE = /(?<trailing_spaces>\s+)(?<ending>#{LINE_1_ENDING})/.freeze
        TRAILING_STYLE_OFFENSE = /(?<beginning>#{LINE_2_BEGINNING})(?<leading_spaces>\s+)/.freeze
        private_constant :LINE_1_ENDING, :LINE_2_BEGINNING,
                         :LEADING_STYLE_OFFENSE, :TRAILING_STYLE_OFFENSE

        # When both cops are activated and run in the same iteration of the correction loop,
        # `Style/StringLiterals` undoes the moving of spaces that
        # `Layout/LineContinuationLeadingSpace` performs. This is because `Style/StringLiterals`
        # takes the original string content and transforms it, rather than just modifying the
        # delimiters, in order to handle escaping for quotes within the string.
        def self.autocorrect_incompatible_with
          [Style::StringLiterals]
        end

        def on_dstr(node)
          # Quick check if we possibly have line continuations.
          return unless node.source.include?('\\')

          end_of_first_line = node.source_range.begin_pos - node.source_range.column

          lines = raw_lines(node)
          lines.each_cons(2).with_index(node.first_line) do |(raw_line_one, raw_line_two), line_num|
            end_of_first_line += raw_line_one.length

            next unless continuation?(raw_line_one, line_num, node)

            investigate(raw_line_one, raw_line_two, end_of_first_line)
          end
        end

        private

        def raw_lines(node)
          processed_source.raw_source.lines[node.first_line - 1, line_range(node).size]
        end

        def investigate(first_line, second_line, end_of_first_line)
          if enforced_style_leading?
            investigate_leading_style(first_line, second_line, end_of_first_line)
          else
            investigate_trailing_style(first_line, second_line, end_of_first_line)
          end
        end

        def investigate_leading_style(first_line, second_line, end_of_first_line)
          matches = first_line.match(LEADING_STYLE_OFFENSE)
          return if matches.nil?

          offense_range = leading_offense_range(end_of_first_line, matches)
          add_offense(offense_range) do |corrector|
            insert_pos = end_of_first_line + second_line[LINE_2_BEGINNING].length
            autocorrect(corrector, offense_range, insert_pos, matches[:trailing_spaces])
          end
        end

        def investigate_trailing_style(first_line, second_line, end_of_first_line)
          matches = second_line.match(TRAILING_STYLE_OFFENSE)
          return if matches.nil?

          offense_range = trailing_offense_range(end_of_first_line, matches)
          add_offense(offense_range) do |corrector|
            insert_pos = end_of_first_line - first_line[LINE_1_ENDING].length
            autocorrect(corrector, offense_range, insert_pos, matches[:leading_spaces])
          end
        end

        def continuation?(line, line_num, node)
          return false unless line.end_with?("\\\n")

          # Ensure backslash isn't part of a token spanning to the next line.
          node.children.none? { |c| (c.first_line...c.last_line).cover?(line_num) && c.multiline? }
        end

        def autocorrect(corrector, offense_range, insert_pos, spaces)
          corrector.remove(offense_range)
          corrector.replace(range_between(insert_pos, insert_pos), spaces)
        end

        def leading_offense_range(end_of_first_line, matches)
          end_pos = end_of_first_line - matches[:ending].length
          begin_pos = end_pos - matches[:trailing_spaces].length
          range_between(begin_pos, end_pos)
        end

        def trailing_offense_range(end_of_first_line, matches)
          begin_pos = end_of_first_line + matches[:beginning].length
          end_pos = begin_pos + matches[:leading_spaces].length
          range_between(begin_pos, end_pos)
        end

        def message(_range)
          if enforced_style_leading?
            'Move trailing spaces to the start of the next line.'
          else
            'Move leading spaces to the end of the previous line.'
          end
        end

        def enforced_style_leading?
          cop_config['EnforcedStyle'] == 'leading'
        end
      end
    end
  end
end
