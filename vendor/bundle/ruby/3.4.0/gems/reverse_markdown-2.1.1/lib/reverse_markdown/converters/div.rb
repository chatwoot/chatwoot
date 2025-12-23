module ReverseMarkdown
  module Converters
    class Div < Base
      def convert(node, state = {})
        "\n" << treat_children(node, state) << "\n"
      end
    end

    register :div,     Div.new
    register :article, Div.new
  end
end
