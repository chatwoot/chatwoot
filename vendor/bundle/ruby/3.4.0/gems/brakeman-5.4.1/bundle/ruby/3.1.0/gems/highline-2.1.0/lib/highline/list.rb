# coding: utf-8

class HighLine
  # List class with some convenience methods like {#col_down}.
  class List
    # Original given *items* argument.
    # It's frozen at initialization time and
    # all later transformations will happen on {#list}.
    # @return [Array]
    attr_reader :items

    # Number of columns for each list row.
    # @return [Integer]
    attr_reader :cols

    # Columns turn into rows in transpose mode.
    # @return [Boolean]
    #
    # @example A two columns array like this:
    #   [ [ "a", "b" ],
    #     [ "c", "d" ],
    #     [ "e", "f" ],
    #     [ "g", "h" ],
    #     [ "i", "j" ] ]
    #
    # @example When in transpose mode will be like this:
    #   [ [ "a", "c", "e", "g", "i" ],
    #     [ "b", "d", "f", "h", "j" ] ]
    #
    # @see #col_down_mode

    attr_reader :transpose_mode

    # Content are distributed first by column in col down mode.
    # @return [Boolean]
    #
    # @example A two columns array like this:
    #   [ [ "a", "b" ],
    #     [ "c", "d" ],
    #     [ "e", "f" ],
    #     [ "g", "h" ],
    #     [ "i", "j" ] ]
    #
    # @example In col down mode will be like this:
    #   [ [ "a", "f"],
    #     [ "b", "g"],
    #     [ "c", "h"],
    #     [ "d", "i"],
    #     [ "e", "j"] ]
    #
    # @see #transpose_mode

    attr_reader :col_down_mode

    # @param items [#to_a] an array of items to compose the list.
    # @param options [Hash] a hash of options to tailor the list.
    # @option options [Boolean] :transpose (false) set {#transpose_mode}.
    # @option options [Boolean] :col_down (false) set {#col_down_mode}.
    # @option options [Integer] :cols (1) set {#cols}.

    def initialize(items, options = {})
      @items          = items.to_a.dup.freeze
      @transpose_mode = options.fetch(:transpose) { false }
      @col_down_mode  = options.fetch(:col_down)  { false }
      @cols           = options.fetch(:cols)      { 1 }
      build
    end

    # Transpose the (already sliced by rows) list,
    #   turning its rows into columns.
    # @return [self]
    def transpose
      first_row = @list[0]
      other_rows = @list[1..-1]
      @list = first_row.zip(*other_rows)
      self
    end

    # Slice the list by rows and transpose it.
    # @return [self]
    def col_down
      slice_by_rows
      transpose
      self
    end

    # Slice the list by rows. The row count is calculated
    # indirectly based on the {#cols} param and the items count.
    # @return [self]
    def slice_by_rows
      @list = items_sliced_by_rows
      self
    end

    # Slice the list by cols based on the {#cols} param.
    # @return [self]
    def slice_by_cols
      @list = items_sliced_by_cols
      self
    end

    # Set the cols number.
    # @return [self]
    def cols=(cols)
      @cols = cols
      build
    end

    # Returns an Array representation of the list
    # in its current state.
    # @return [Array] @list.dup
    def list
      @list.dup
    end

    # (see #list)
    def to_a
      list
    end

    # Stringfies the list in its current state.
    # It joins each individual _cell_ with the current
    # {#row_join_string} between them.
    # It joins each individual row with a
    # newline character. So the returned String is
    # suitable to be directly outputed
    # to the screen, preserving row/columns divisions.
    # @return [String]
    def to_s
      list.map { |row| stringfy(row) }.join
    end

    # The String that will be used to join each
    # cell of the list and stringfying it.
    # @return [String] defaults to " " (space)
    def row_join_string
      @row_join_string ||= "  "
    end

    # Set the {#row_join_string}.
    # @see #row_join_string
    attr_writer :row_join_string

    # Returns the row join string size.
    # Useful for calculating the actual size of
    # rendered list.
    # @return [Integer]
    def row_join_str_size
      row_join_string.size
    end

    private

    def build
      slice_by_cols
      transpose if transpose_mode
      col_down  if col_down_mode
      self
    end

    def items_sliced_by_cols
      items.each_slice(cols).to_a
    end

    def items_sliced_by_rows
      items.each_slice(row_count).to_a
    end

    def row_count
      (items.count / cols.to_f).ceil
    end

    def stringfy(row)
      row.compact.join(row_join_string) + "\n"
    end
  end
end
