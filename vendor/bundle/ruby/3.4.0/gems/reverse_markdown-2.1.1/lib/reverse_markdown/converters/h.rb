module ReverseMarkdown
  module Converters
    class H < Base
      def convert(node, state = {})
        prefix = '#' * node.name[/\d/].to_i
        ["\n", prefix, ' ', treat_children(node, state), "\n"].join
      end
    end

    register :h1, H.new
    register :h2, H.new
    register :h3, H.new
    register :h4, H.new
    register :h5, H.new
    register :h6, H.new
  end
end
