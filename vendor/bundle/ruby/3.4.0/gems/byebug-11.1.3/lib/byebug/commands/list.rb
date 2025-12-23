# frozen_string_literal: true

require_relative "../command"
require_relative "../source_file_formatter"
require_relative "../helpers/file"
require_relative "../helpers/parse"

module Byebug
  #
  # List parts of the source code.
  #
  class ListCommand < Command
    include Helpers::FileHelper
    include Helpers::ParseHelper

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* l(?:ist)? (?:\s*([-=])|\s+(\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        l[ist][[-=]][ nn-mm]

        #{short_description}

        Lists lines forward from current line or from the place where code was
        last listed. If "list-" is specified, lists backwards instead. If
        "list=" is specified, lists from current line regardless of where code
        was last listed. A line range can also be specified to list specific
        sections of code.
      DESCRIPTION
    end

    def self.short_description
      "Lists lines of source code"
    end

    def execute
      msg = "No sourcefile available for #{frame.file}"
      raise(msg) unless File.exist?(frame.file)

      b, e = range(@match[2])

      display_lines(b, e)

      processor.prev_line = b
    end

    private

    #
    # Line range to be printed by `list`.
    #
    # If <input> is set, range is parsed from it.
    #
    # Otherwise it's automatically chosen.
    #
    def range(input)
      return auto_range(@match[1] || "+") unless input

      b, e = parse_range(input)
      raise("Invalid line range") unless valid_range?(b, e)

      [b, e]
    end

    def valid_range?(first, last)
      first <= last && (1..max_line).cover?(first) && (1..max_line).cover?(last)
    end

    #
    # Set line range to be printed by list
    #
    # @return first line number to list
    # @return last line number to list
    #
    def auto_range(direction)
      prev_line = processor.prev_line

      if direction == "=" || prev_line.nil?
        source_file_formatter.range_around(frame.line)
      else
        source_file_formatter.range_from(move(prev_line, size, direction))
      end
    end

    def parse_range(input)
      first, err = get_int(lower_bound(input), "List", 1, max_line)
      raise(err) unless first

      if upper_bound(input)
        last, err = get_int(upper_bound(input), "List", 1, max_line)
        raise(err) unless last

        last = amend_final(last)
      else
        first -= (size / 2)
      end

      [first, last || move(first, size - 1)]
    end

    def move(line, size, direction = "+")
      line.send(direction, size)
    end

    #
    # Show a range of lines in the current file.
    #
    # @param min [Integer] Lower bound
    # @param max [Integer] Upper bound
    #
    def display_lines(min, max)
      puts "\n[#{min}, #{max}] in #{frame.file}"

      puts source_file_formatter.lines(min, max).join
    end

    #
    # @param range [String] A string with an integer range format
    #
    # @return [String] The lower bound of the given range
    #
    def lower_bound(range)
      split_range(range)[0]
    end

    #
    # @param range [String] A string with an integer range format
    #
    # @return [String] The upper bound of the given range
    #
    def upper_bound(range)
      split_range(range)[1]
    end

    #
    # @param str [String] A string with an integer range format
    #
    # @return [Array] The upper & lower bounds of the given range
    #
    def split_range(str)
      str.split(/[-,]/)
    end

    extend Forwardable

    def_delegators :source_file_formatter, :amend_final, :size, :max_line

    def source_file_formatter
      @source_file_formatter ||= SourceFileFormatter.new(
        frame.file,
        ->(n) { n == frame.line ? "=>" : "  " }
      )
    end
  end
end
