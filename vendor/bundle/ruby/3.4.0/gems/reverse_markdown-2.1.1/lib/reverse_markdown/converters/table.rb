module ReverseMarkdown
  module Converters
    class Table < Base
      def convert(node, state = {})
        "\n\n" << treat_children(node, state) << "\n"
      end
    end

    register :table, Table.new
  end
end
