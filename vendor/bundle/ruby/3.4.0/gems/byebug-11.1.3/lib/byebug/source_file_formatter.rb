# frozen_string_literal: true

require_relative "helpers/file"
require_relative "setting"

module Byebug
  #
  # Formats specific line ranges in a source file
  #
  class SourceFileFormatter
    include Helpers::FileHelper

    attr_reader :file, :annotator

    def initialize(file, annotator)
      @file = file
      @annotator = annotator
    end

    def lines(min, max)
      File.foreach(file).with_index.map do |line, lineno|
        next unless (min..max).cover?(lineno + 1)

        format(
          "%<annotation>s %<lineno>#{max.to_s.size}d: %<source>s",
          annotation: annotator.call(lineno + 1),
          lineno: lineno + 1,
          source: line
        )
      end
    end

    def lines_around(center)
      lines(*range_around(center))
    end

    def range_around(center)
      range_from(center - size / 2)
    end

    def range_from(min)
      first = amend_initial(min)

      [first, first + size - 1]
    end

    def amend_initial(line)
      amend(line, max_initial_line)
    end

    def amend_final(line)
      amend(line, max_line)
    end

    def max_initial_line
      max_line - size + 1
    end

    def max_line
      @max_line ||= n_lines(file)
    end

    def size
      [Setting[:listsize], max_line].min
    end

    def amend(line, ceiling)
      [ceiling, [1, line].max].min
    end
  end
end
