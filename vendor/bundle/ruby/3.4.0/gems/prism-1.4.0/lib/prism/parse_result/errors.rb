# frozen_string_literal: true

require "stringio"

module Prism
  class ParseResult < Result
    # An object to represent the set of errors on a parse result. This object
    # can be used to format the errors in a human-readable way.
    class Errors
      # The parse result that contains the errors.
      attr_reader :parse_result

      # Initialize a new set of errors from the given parse result.
      def initialize(parse_result)
        @parse_result = parse_result
      end

      # Formats the errors in a human-readable way and return them as a string.
      def format
        error_lines = {} #: Hash[Integer, Array[ParseError]]
        parse_result.errors.each do |error|
          location = error.location
          (location.start_line..location.end_line).each do |line|
            error_lines[line] ||= []
            error_lines[line] << error
          end
        end

        source_lines = parse_result.source.source.lines
        source_lines << "" if error_lines.key?(source_lines.size + 1)

        io = StringIO.new
        source_lines.each.with_index(1) do |line, line_number|
          io.puts(line)

          (error_lines.delete(line_number) || []).each do |error|
            location = error.location

            case line_number
            when location.start_line
              io.print(" " * location.start_column + "^")

              if location.start_line == location.end_line
                if location.start_column != location.end_column
                  io.print("~" * (location.end_column - location.start_column - 1))
                end

                io.puts(" " + error.message)
              else
                io.puts("~" * (line.bytesize - location.start_column))
              end
            when location.end_line
              io.puts("~" * location.end_column + " " + error.message)
            else
              io.puts("~" * line.bytesize)
            end
          end
        end

        io.puts
        io.string
      end
    end
  end
end
