module ReverseMarkdown
  module Converters
    class Figure < Base
      def convert(node, state = {})
        content = treat_children(node, state)
        "\n#{content.strip}\n"
      end
    end

    register :figure, Figure.new
  end
end
