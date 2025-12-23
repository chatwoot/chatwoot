module ReverseMarkdown
  module Converters
    class Ol < Base
      def convert(node, state = {})
        ol_count = state.fetch(:ol_count, 0) + 1
        "\n" << treat_children(node, state.merge(ol_count: ol_count))
      end
    end

    register :ol, Ol.new
    register :ul, Ol.new
  end
end
