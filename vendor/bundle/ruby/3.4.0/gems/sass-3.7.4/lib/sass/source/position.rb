module Sass::Source
  class Position
    # The one-based line of the document associated with the position.
    #
    # @return [Integer]
    attr_accessor :line

    # The one-based offset in the line of the document associated with the
    # position.
    #
    # @return [Integer]
    attr_accessor :offset

    # @param line [Integer] The source line
    # @param offset [Integer] The source offset
    def initialize(line, offset)
      @line = line
      @offset = offset
    end

    # @return [String] A string representation of the source position.
    def inspect
      "#{line.inspect}:#{offset.inspect}"
    end

    # @param str [String] The string to move through.
    # @return [Position] The source position after proceeding forward through
    #   `str`.
    def after(str)
      newlines = str.count("\n")
      Position.new(line + newlines,
        if newlines == 0
          offset + str.length
        else
          str.length - str.rindex("\n") - 1
        end)
    end
  end
end
