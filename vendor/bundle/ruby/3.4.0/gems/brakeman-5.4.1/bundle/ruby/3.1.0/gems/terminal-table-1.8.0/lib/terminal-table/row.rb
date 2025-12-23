module Terminal
  class Table
    class Row

      ##
      # Row cells

      attr_reader :cells

      attr_reader :table

      ##
      # Initialize with _width_ and _options_.

      def initialize table, array = []
        @cell_index = 0
        @table = table
        @cells = []
        array.each { |item| self << item }
      end

      def add_cell item
        options = item.is_a?(Hash) ? item : {:value => item}
        cell = Cell.new(options.merge(:index => @cell_index, :table => @table))
        @cell_index += cell.colspan
        @cells << cell
      end
      alias << add_cell

      def [] index
        cells[index]
      end

      def height
        cells.map { |c| c.lines.count }.max || 0
      end

      def render
        y = @table.style.border_y
        (0...height).to_a.map do |line|
          y + cells.map do |cell|
            cell.render(line)
          end.join(y) + y
        end.join("\n")
      end

      def number_of_columns
        @cells.collect(&:colspan).inject(0, &:+)
      end
    end
  end
end
