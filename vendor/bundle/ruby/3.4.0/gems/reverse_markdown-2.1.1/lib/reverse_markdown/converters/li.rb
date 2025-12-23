module ReverseMarkdown
  module Converters
    class Li < Base
      def convert(node, state = {})
        contains_child_paragraph = node.first_element_child ? node.first_element_child.name == 'p' : false
        content_node             = contains_child_paragraph ? node.first_element_child : node
        content                  = treat_children(content_node, state)
        indentation              = indentation_from(state)
        prefix                   = prefix_for(node)

        "#{indentation}#{prefix}#{content.chomp}\n" +
          (contains_child_paragraph ? "\n" : '')
      end

      def prefix_for(node)
        if node.parent.name == 'ol'
          index = node.parent.xpath('li').index(node)
          "#{index.to_i + 1}. "
        else
          '- '
        end
      end

      def indentation_from(state)
        length = state.fetch(:ol_count, 0)
        '  ' * [length - 1, 0].max
      end
    end

    register :li, Li.new
  end
end
