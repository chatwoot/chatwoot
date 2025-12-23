module ReverseMarkdown
  module Converters
    class P < Base
      def convert(node, state = {})
        "\n\n" << treat_children(node, state).strip << "\n\n"
      end
    end

    register :p, P.new
  end
end
