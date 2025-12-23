# frozen_string_literal: true

module RuboCop
  module Cop
    # Methods that calculate and return Parser::Source::Ranges
    module RangeHelp
      BYTE_ORDER_MARK = 0xfeff # The Unicode codepoint
      NOT_GIVEN = Module.new

      private

      def source_range(source_buffer, line_number, column, length = 1)
        if column.is_a?(Range)
          column_index = column.begin
          length = column.size
        else
          column_index = column
        end

        line_begin_pos = if line_number.zero?
                           0
                         else
                           source_buffer.line_range(line_number).begin_pos
                         end
        begin_pos = line_begin_pos + column_index
        end_pos = begin_pos + length

        Parser::Source::Range.new(source_buffer, begin_pos, end_pos)
      end

      # A range containing only the contents of a literal with delimiters (e.g. in
      # `%i{1 2 3}` this will be the range covering `1 2 3` only).
      def contents_range(node)
        range_between(node.loc.begin.end_pos, node.loc.end.begin_pos)
      end

      # A range containing the first to the last argument
      # of a method call or method definition.
      # def foo(a, b:)
      #         ^^^^^
      # bar(1, 2, 3, &blk)
      #     ^^^^^^^^^^^^^
      # baz { |x, y:, z:| }
      #        ^^^^^^^^^
      def arguments_range(node)
        node.first_argument.source_range.join(node.last_argument.source_range)
      end

      def range_between(start_pos, end_pos)
        Parser::Source::Range.new(processed_source.buffer, start_pos, end_pos)
      end

      def range_with_surrounding_comma(range, side = :both)
        buffer = @processed_source.buffer
        src = buffer.source

        go_left, go_right = directions(side)

        begin_pos = range.begin_pos
        end_pos = range.end_pos
        begin_pos = move_pos(src, begin_pos, -1, go_left, /,/)
        end_pos = move_pos(src, end_pos, 1, go_right, /,/)

        Parser::Source::Range.new(buffer, begin_pos, end_pos)
      end

      def range_with_surrounding_space(range_positional = NOT_GIVEN, # rubocop:disable Metrics/ParameterLists
                                       range: NOT_GIVEN, side: :both, newlines: true,
                                       whitespace: false, continuations: false,
                                       buffer: @processed_source.buffer)
        range = range_positional unless range_positional == NOT_GIVEN

        src = buffer.source

        go_left, go_right = directions(side)

        begin_pos = range.begin_pos
        begin_pos = final_pos(src, begin_pos, -1, continuations, newlines, whitespace) if go_left
        end_pos = range.end_pos
        end_pos = final_pos(src, end_pos, 1, continuations, newlines, whitespace) if go_right
        Parser::Source::Range.new(buffer, begin_pos, end_pos)
      end

      def range_by_whole_lines(range, include_final_newline: false,
                               buffer: @processed_source.buffer)
        last_line = buffer.source_line(range.last_line)
        end_offset = last_line.length - range.last_column
        end_offset += 1 if include_final_newline

        range.adjust(begin_pos: -range.column, end_pos: end_offset).intersect(buffer.source_range)
      end

      def column_offset_between(base_range, range)
        effective_column(base_range) - effective_column(range)
      end

      ## Helpers for above range methods. Do not use inside Cops.

      # Returns the column attribute of the range, except if the range is on
      # the first line and there's a byte order mark at the beginning of that
      # line, in which case 1 is subtracted from the column value. This gives
      # the column as it appears when viewing the file in an editor.
      def effective_column(range)
        if range.line == 1 && @processed_source.raw_source.codepoints.first == BYTE_ORDER_MARK
          range.column - 1
        else
          range.column
        end
      end

      def directions(side)
        if side == :both
          [true, true]
        else
          [side == :left, side == :right]
        end
      end

      # rubocop:disable Metrics/ParameterLists
      def final_pos(src, pos, increment, continuations, newlines, whitespace)
        pos = move_pos(src, pos, increment, true, /[ \t]/)
        pos = move_pos_str(src, pos, increment, continuations, "\\\n")
        pos = move_pos(src, pos, increment, newlines, /\n/)
        move_pos(src, pos, increment, whitespace, /\s/)
      end
      # rubocop:enable Metrics/ParameterLists

      def move_pos(src, pos, step, condition, regexp)
        offset = step == -1 ? -1 : 0
        pos += step while condition && regexp.match?(src[pos + offset])
        pos.negative? ? 0 : pos
      end

      def move_pos_str(src, pos, step, condition, needle)
        size = needle.length
        offset = step == -1 ? -size : 0
        pos += size * step while condition && src[pos + offset, size] == needle
        pos.negative? ? 0 : pos
      end

      def range_with_comments_and_lines(node)
        range_by_whole_lines(range_with_comments(node), include_final_newline: true)
      end

      def range_with_comments(node)
        ranges = [node, *@processed_source.ast_with_comments[node]].map(&:source_range)
        ranges.reduce do |result, range|
          add_range(result, range)
        end
      end

      def add_range(range1, range2)
        range1.with(
          begin_pos: [range1.begin_pos, range2.begin_pos].min,
          end_pos: [range1.end_pos, range2.end_pos].max
        )
      end
    end
  end
end
