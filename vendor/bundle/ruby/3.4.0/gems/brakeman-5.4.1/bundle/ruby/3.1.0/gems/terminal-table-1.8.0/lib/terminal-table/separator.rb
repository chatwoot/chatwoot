module Terminal
  class Table
    class Separator < Row

      def render
        arr_x = (0...@table.number_of_columns).to_a.map do |i|
          @table.style.border_x * (@table.column_width(i) + @table.cell_padding)
        end
        border_i = @table.style.border_i
        border_i + arr_x.join(border_i) + border_i
      end
    end
  end
end
