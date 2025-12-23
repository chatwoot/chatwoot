module ReverseMarkdown
  module Converters
    class PassThrough < Base
      def convert(node, state = {})
        node.to_s
      end
    end
  end
end
