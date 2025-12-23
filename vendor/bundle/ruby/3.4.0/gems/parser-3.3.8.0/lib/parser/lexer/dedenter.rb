# frozen_string_literal: true

module Parser

  class Lexer::Dedenter
    # Tab (\t) counts as 8 spaces
    TAB_WIDTH = 8

    def initialize(dedent_level)
      @dedent_level = dedent_level
      @at_line_begin = true
      @indent_level  = 0
    end

    # For a heredoc like
    #   <<-HERE
    #     a
    #     b
    #   HERE
    # this method gets called with "  a\n" and "  b\n"
    #
    # However, the following heredoc:
    #
    #   <<-HERE
    #     a\
    #     b
    #   HERE
    # calls this method only once with a string "  a\\\n  b\n"
    #
    # This is important because technically it's a single line,
    # but it has to be concatenated __after__ dedenting.
    #
    # It has no effect for non-squiggly heredocs, i.e. it simply removes "\\\n"
    # Of course, lexer could do it but once again: it's all because of dedenting.
    #
    def dedent(string)
      original_encoding = string.encoding
      # Prevent the following error when processing binary encoded source.
      # "\xC0".split # => ArgumentError (invalid byte sequence in UTF-8)
      lines = string.force_encoding(Encoding::BINARY).split("\\\n")
      if lines.length == 1
        # If the line continuation sequence was found but there is no second
        # line, it was not really a line continuation and must be ignored.
        lines = [string.force_encoding(original_encoding)]
      else
        lines.map! {|s| s.force_encoding(original_encoding) }
      end

      if @at_line_begin
        lines_to_dedent = lines
      else
        _first, *lines_to_dedent = lines
      end

      lines_to_dedent.each do |line|
        left_to_remove = @dedent_level
        remove = 0

        line.each_char do |char|
          break if left_to_remove <= 0
          case char
          when ?\s
            remove += 1
            left_to_remove -= 1
          when ?\t
            break if TAB_WIDTH * (remove / TAB_WIDTH + 1) > @dedent_level
            remove += 1
            left_to_remove -= TAB_WIDTH
          else
            # no more spaces or tabs
            break
          end
        end

        line.slice!(0, remove)
      end

      string.replace(lines.join)

      @at_line_begin = string.end_with?("\n")
    end

    def interrupt
      @at_line_begin = false
    end
  end

end
