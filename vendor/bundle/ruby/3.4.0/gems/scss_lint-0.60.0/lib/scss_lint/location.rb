module SCSSLint
  # Stores a location of {Lint} in a source.
  class Location
    include Comparable

    attr_reader :line, :column, :length

    # @param line [Integer] One-based index
    # @param column [Integer] One-based index
    # @param length [Integer] Number of characters, including the first character
    def initialize(line = 1, column = 1, length = 1)
      raise ArgumentError, "Line must be more than 0, passed #{line}" if line < 1
      raise ArgumentError, "Column must be more than 0, passed #{column}" if column < 1
      raise ArgumentError, "Length must be more than 0, passed #{length}" if length < 1

      @line   = line
      @column = column
      @length = length
    end

    def ==(other)
      %i[line column length].all? do |attr|
        send(attr) == other.send(attr)
      end
    end

    alias eql? ==

    def <=>(other)
      %i[line column length].each do |attr|
        result = send(attr) <=> other.send(attr)
        return result unless result == 0
      end

      0
    end
  end
end
