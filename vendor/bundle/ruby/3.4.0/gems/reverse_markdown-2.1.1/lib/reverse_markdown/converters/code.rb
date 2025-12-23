module ReverseMarkdown
  module Converters
    class Code < Base
      def convert(node, state = {})
        "`#{node.text}`"
      end
    end

    register :code, Code.new
  end
end
