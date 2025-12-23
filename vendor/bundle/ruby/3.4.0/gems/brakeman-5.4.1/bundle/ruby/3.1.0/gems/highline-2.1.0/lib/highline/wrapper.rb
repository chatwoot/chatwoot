# coding: utf-8

require "English"

class HighLine
  # A simple Wrapper module that is aware of ANSI escape codes.
  # It compensates for the ANSI escape codes so it works on the
  # actual (visual) line length.
  module Wrapper
    #
    # Wrap a sequence of _lines_ at _wrap_at_ characters per line.  Existing
    # newlines will not be affected by this process, but additional newlines
    # may be added.
    #
    # @param text [String] text to be wrapped
    # @param wrap_at [#to_i] column count to wrap the text into
    def self.wrap(text, wrap_at)
      return text unless wrap_at
      wrap_at = Integer(wrap_at)

      wrapped = []
      text.each_line do |line|
        # take into account color escape sequences when wrapping
        wrap_at += (line.length - actual_length(line))
        while line =~ /([^\n]{#{wrap_at + 1},})/
          search  = Regexp.last_match(1).dup
          replace = Regexp.last_match(1).dup
          index = replace.rindex(" ", wrap_at)
          if index
            replace[index, 1] = "\n"
            replace.sub!(/\n[ \t]+/, "\n")
            line.sub!(search, replace)
          else
            line[$LAST_MATCH_INFO.begin(1) + wrap_at, 0] = "\n"
          end
        end
        wrapped << line
      end
      wrapped.join
    end

    #
    # Returns the length of the passed +string_with_escapes+, minus and color
    # sequence escapes.
    #
    # @param string_with_escapes [String] any ANSI colored String
    # @return [Integer] length based on the visual size of the String
    #   (without the escape codes)
    def self.actual_length(string_with_escapes)
      string_with_escapes.to_s.gsub(/\e\[\d{1,2}m/, "").length
    end
  end
end
