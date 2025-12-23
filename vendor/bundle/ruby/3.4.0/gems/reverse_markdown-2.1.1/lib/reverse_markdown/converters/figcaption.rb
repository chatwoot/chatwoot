module ReverseMarkdown
  module Converters
    class FigCaption < Base
      def convert(node, state = {})
        if node.text.strip.empty?
          ""
        else
          "\n" << "_#{node.text.strip}_" << "\n"
        end
      end
    end

    register :figcaption, FigCaption.new
  end
end
