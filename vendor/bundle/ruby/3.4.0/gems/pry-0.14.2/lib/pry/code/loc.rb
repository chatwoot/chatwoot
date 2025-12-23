# frozen_string_literal: true

class Pry
  class Code
    # Represents a line of code (which may, in fact, contain multiple lines if
    # the entirety was eval'd as a single unit following the `edit` command).
    #
    # A line of code is a tuple, which consists of a line and a line number. A
    # `LOC` object's state (namely, the line parameter) can be changed via
    # instance methods.  `Pry::Code` heavily uses this class.
    #
    # @api private
    # @example
    #   loc = LOC.new("def example\n  :example\nend", 1)
    #   puts loc.line
    #   def example
    #     :example
    #   end
    #   #=> nil
    #
    #   loc.indent(3)
    #   loc.line #=> "   def example\n  :example\nend"
    class LOC
      # @return [Array<String, Integer>]
      attr_reader :tuple

      # @param [String] line The line of code.
      # @param [Integer] lineno The position of the +line+.
      def initialize(line, lineno)
        @tuple = [line.chomp, lineno.to_i]
      end

      # @return [Boolean]
      def ==(other)
        other.tuple == tuple
      end

      def dup
        self.class.new(line, lineno)
      end

      # @return [String]
      def line
        tuple.first
      end

      # @return [Integer]
      def lineno
        tuple.last
      end

      # Paints the `line` of code.
      #
      # @param [Symbol] code_type
      # @return [void]
      def colorize(code_type)
        tuple[0] = SyntaxHighlighter.highlight(line, code_type)
      end

      # Prepends the line number `lineno` to the `line`.
      #
      # @param [Integer] max_width
      # @return [void]
      def add_line_number(max_width = 0, color = false)
        padded = lineno.to_s.rjust(max_width)
        colorized_lineno =
          if color
            Pry::Helpers::BaseHelpers.colorize_code(padded)
          else
            padded
          end
        properly_padded_line = handle_multiline_entries_from_edit_command(line, max_width)
        tuple[0] = "#{colorized_lineno}: #{properly_padded_line}"
      end

      # Prepends a marker "=>" or an empty marker to the +line+.
      #
      # @param [Integer] marker_lineno If it is equal to the `lineno`, then
      #   prepend a hashrocket. Otherwise, an empty marker.
      # @return [void]
      def add_marker(marker_lineno)
        tuple[0] =
          if lineno == marker_lineno
            " => #{line}"
          else
            "    #{line}"
          end
      end

      # Indents the `line` with +distance+ spaces.
      #
      # @param [Integer] distance
      # @return [void]
      def indent(distance)
        tuple[0] = "#{' ' * distance}#{line}"
      end

      def handle_multiline_entries_from_edit_command(line, max_width)
        line.split("\n").map.with_index do |inner_line, i|
          i.zero? ? inner_line : "#{' ' * (max_width + 2)}#{inner_line}"
        end.join("\n")
      end
    end
  end
end
