# coding: utf-8

require "highline/template_renderer"
require "highline/wrapper"
require "highline/list"

class HighLine
  #
  # This class is a utility for quickly and easily laying out lists
  # to be used by HighLine.
  #
  class ListRenderer
    # Items list
    # @return [Array]
    attr_reader :items

    # @return [Symbol] the current mode the List is being rendered
    # @see #initialize for more details see mode parameter of #initialize
    attr_reader :mode

    # Changes the behaviour of some modes. Example, in :inline mode
    # the option is treated as the 'end separator' (defaults to " or ")
    # @return option parameter that changes the behaviour of some modes.
    attr_reader :option

    # @return [HighLine] context
    attr_reader :highline

    # The only required parameters are _items_ and _highline_.
    # @param items [Array] the Array of items to list
    # @param mode [Symbol] controls how that list is formed
    # @param option has different effects, depending on the _mode_.
    # @param highline [HighLine] a HighLine instance to direct the output to.
    #
    # Recognized modes are:
    #
    # <tt>:columns_across</tt>::         _items_ will be placed in columns,
    #                                    flowing from left to right.  If given,
    #                                    _option_ is the number of columns to be
    #                                    used.  When absent, columns will be
    #                                    determined based on _wrap_at_ or a
    #                                    default of 80 characters.
    # <tt>:columns_down</tt>::           Identical to <tt>:columns_across</tt>,
    #                                    save flow goes down.
    # <tt>:uneven_columns_across</tt>::  Like <tt>:columns_across</tt> but each
    #                                    column is sized independently.
    # <tt>:uneven_columns_down</tt>::    Like <tt>:columns_down</tt> but each
    #                                    column is sized independently.
    # <tt>:inline</tt>::                 All _items_ are placed on a single
    #                                    line. The last two _items_ are
    #                                    separated by _option_ or a default of
    #                                    " or ".  All other _items_ are
    #                                    separated by ", ".
    # <tt>:rows</tt>::                   The default mode.  Each of the _items_
    #                                    is placed on its own line. The _option_
    #                                    parameter is ignored in this mode.
    #
    # Each member of the _items_ Array is passed through ERb and thus can
    # contain their own expansions. Color escape expansions do not contribute to
    # the final field width.

    def initialize(items, mode = :rows, option = nil, highline)
      @highline = highline
      @mode     = mode
      @option   = option
      @items    = render_list_items(items)
    end

    # Render the list using the appropriate mode and options.
    # @return [String] rendered list as String
    def render
      return "" if items.empty?

      case mode
      when :inline
        list_inline_mode
      when :columns_across
        list_columns_across_mode
      when :columns_down
        list_columns_down_mode
      when :uneven_columns_across
        list_uneven_columns_mode
      when :uneven_columns_down
        list_uneven_columns_down_mode
      else
        list_default_mode
      end
    end

    private

    def render_list_items(items)
      items.to_ary.map do |item|
        item = String(item)
        template = if ERB.instance_method(:initialize).parameters.assoc(:key) # Ruby 2.6+
          ERB.new(item, trim_mode: "%")
        else
          ERB.new(item, nil, "%")
        end
        template_renderer =
          HighLine::TemplateRenderer.new(template, self, highline)
        template_renderer.render
      end
    end

    def list_default_mode
      items.map { |i| "#{i}\n" }.join
    end

    def list_inline_mode
      end_separator = option || " or "

      if items.size == 1
        items.first
      else
        items[0..-2].join(", ") + "#{end_separator}#{items.last}"
      end
    end

    def list_columns_across_mode
      HighLine::List.new(right_padded_items, cols: col_count).to_s
    end

    def list_columns_down_mode
      HighLine::List.new(
        right_padded_items,
        cols: col_count,
        col_down: true
      ).to_s
    end

    def list_uneven_columns_mode(list = nil)
      list ||= HighLine::List.new(items)

      col_max = option || items.size
      col_max.downto(1) do |column_count|
        list.cols = column_count
        widths = get_col_widths(list)

        if column_count == 1 || # last guess
           inside_line_size_limit?(widths) || # good guess
           option # defined by user
          return pad_uneven_rows(list, widths)
        end
      end
    end

    def list_uneven_columns_down_mode
      list = HighLine::List.new(items, col_down: true)
      list_uneven_columns_mode(list)
    end

    def pad_uneven_rows(list, widths)
      right_padded_list = Array(list).map do |row|
        right_pad_row(row.compact, widths)
      end
      stringfy_list(right_padded_list)
    end

    def stringfy_list(list)
      list.map { |row| row_to_s(row) }.join
    end

    def row_to_s(row)
      row.compact.join(row_join_string) + "\n"
    end

    def right_pad_row(row, widths)
      row.zip(widths).map do |field, width|
        right_pad_field(field, width)
      end
    end

    def right_pad_field(field, width)
      field = String(field) # nil protection
      pad_size = width - actual_length(field)
      field + (pad_char * pad_size)
    end

    def get_col_widths(lines)
      lines = transpose(lines)
      get_segment_widths(lines)
    end

    def get_row_widths(lines)
      get_segment_widths(lines)
    end

    def get_segment_widths(lines)
      lines.map do |col|
        actual_lengths_for(col).max
      end
    end

    def actual_lengths_for(line)
      line.map do |item|
        actual_length(item)
      end
    end

    def transpose(lines)
      lines = Array(lines)
      first_line = lines.shift
      first_line.zip(*lines)
    end

    def inside_line_size_limit?(widths)
      line_size = widths.reduce(0) { |sum, n| sum + n + row_join_str_size }
      line_size <= line_size_limit + row_join_str_size
    end

    def actual_length(text)
      HighLine::Wrapper.actual_length text
    end

    def items_max_length
      @items_max_length ||= max_length(items)
    end

    def max_length(items)
      items.map { |item| actual_length(item) }.max
    end

    def line_size_limit
      @line_size_limit ||= (highline.wrap_at || 80)
    end

    def row_join_string
      @row_join_string ||= "  "
    end

    attr_writer :row_join_string

    def row_join_str_size
      row_join_string.size
    end

    def col_count_calculate
      (line_size_limit + row_join_str_size) /
        (items_max_length + row_join_str_size)
    end

    def col_count
      option || col_count_calculate
    end

    def right_padded_items
      items.map do |item|
        right_pad_field(item, items_max_length)
      end
    end

    def pad_char
      " "
    end

    def row_count
      (items.count / col_count.to_f).ceil
    end
  end
end
