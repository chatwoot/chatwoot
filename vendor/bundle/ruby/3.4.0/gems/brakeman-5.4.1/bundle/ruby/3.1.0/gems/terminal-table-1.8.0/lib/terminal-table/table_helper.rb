module Terminal
  class Table
    module TableHelper
      def table headings = [], *rows, &block
        Terminal::Table.new :headings => headings.to_a, :rows => rows, &block
      end
    end
  end
end
