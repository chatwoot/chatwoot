module Shoulda
  module Matchers
    # @private
    module WordWrap
      TERMINAL_WIDTH = 72

      def word_wrap(document, options = {})
        Document.new(document, **options).wrap
      end
    end

    extend WordWrap

    # @private
    class Document
      def initialize(document, indent: 0)
        @document = document
        @indent = indent
      end

      def wrap
        wrapped_paragraphs.map { |lines| lines.join("\n") }.join("\n\n")
      end

      protected

      attr_reader :document, :indent

      private

      def paragraphs
        document.split(/\n{2,}/)
      end

      def wrapped_paragraphs
        paragraphs.map do |paragraph|
          Paragraph.new(paragraph, indent: indent).wrap
        end
      end
    end

    # @private
    class Text < ::String
      LIST_ITEM_REGEXP = /\A((?:[a-z0-9]+(?:\)|\.)|\*) )/.freeze

      def indented?
        self =~ /\A +/
      end

      def list_item?
        self =~ LIST_ITEM_REGEXP
      end

      def match_as_list_item
        match(LIST_ITEM_REGEXP)
      end
    end

    # @private
    class Paragraph
      def initialize(paragraph, indent: 0)
        @paragraph = Text.new(paragraph)
        @indent = indent
      end

      def wrap
        if paragraph.indented?
          lines
        elsif paragraph.list_item?
          wrap_list_item
        else
          wrap_generic_paragraph
        end
      end

      protected

      attr_reader :paragraph, :indent

      private

      def wrap_list_item
        wrap_lines(combine_list_item_lines(lines))
      end

      def lines
        paragraph.split("\n").map { |line| Text.new(line) }
      end

      def combine_list_item_lines(lines)
        lines.inject([]) do |combined_lines, line|
          if line.list_item?
            combined_lines << line
          else
            combined_lines.last << " #{line}".squeeze(' ')
          end

          combined_lines
        end
      end

      def wrap_lines(lines)
        lines.map { |line| Line.new(line, indent: indent).wrap }
      end

      def wrap_generic_paragraph
        Line.new(combine_paragraph_into_one_line, indent: indent).wrap
      end

      def combine_paragraph_into_one_line
        paragraph.gsub(/\n/, ' ')
      end
    end

    # @private
    class Line
      OFFSETS = { left: -1, right: +1 }.freeze

      def initialize(line, indent: 0)
        @indent = indent
        @original_line = @line_to_wrap = Text.new(line)
        @indentation = ' ' * indent
        @indentation_read = false
      end

      def wrap
        if line_to_wrap.indented?
          [line_to_wrap]
        else
          lines = []

          loop do
            @previous_line_to_wrap = line_to_wrap
            new_line = (indentation || '') + line_to_wrap
            result = wrap_line(new_line)
            lines << normalize_whitespace(result[:fitted_line])

            unless @indentation_read
              @indentation = read_indentation
              @indentation_read = true
            end

            @line_to_wrap = result[:leftover]

            if line_to_wrap.to_s.empty? || previous_line_to_wrap == line_to_wrap
              break
            end
          end

          lines
        end
      end

      protected

      attr_reader :indent, :original_line, :line_to_wrap, :indentation,
        :previous_line_to_wrap

      private

      def read_indentation
        initial_indentation = ' ' * indent
        match = line_to_wrap.match_as_list_item

        if match
          initial_indentation + (' ' * match[1].length)
        else
          initial_indentation
        end
      end

      def wrap_line(line)
        index = nil

        if line.length > Shoulda::Matchers::WordWrap::TERMINAL_WIDTH
          index = determine_where_to_break_line(line, direction: :left)

          if index == -1
            index = determine_where_to_break_line(line, direction: :right)
          end
        end

        if index.nil? || index == -1
          fitted_line = line
          leftover = ''
        else
          fitted_line = line[0..index].rstrip
          leftover = line[index + 1..]
        end

        { fitted_line: fitted_line, leftover: leftover }
      end

      def determine_where_to_break_line(line, args)
        direction = args.fetch(:direction)
        index = Shoulda::Matchers::WordWrap::TERMINAL_WIDTH
        offset = OFFSETS.fetch(direction)

        while line[index] !~ /\s/ && (0...line.length).cover?(index)
          index += offset
        end

        index
      end

      def normalize_whitespace(string)
        indentation + string.strip.squeeze(' ')
      end
    end
  end
end
