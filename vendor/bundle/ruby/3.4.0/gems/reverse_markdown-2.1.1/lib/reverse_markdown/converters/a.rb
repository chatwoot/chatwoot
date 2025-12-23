module ReverseMarkdown
  module Converters
    class A < Base
      def convert(node, state = {})
        name  = treat_children(node, state)
        href  = node['href']
        title = extract_title(node)

        if href.to_s.empty? || name.empty?
          name
        else
          link = "[#{name}](#{href}#{title})"
          link.prepend(' ') if prepend_space?(node)
          link
        end
      end

      private

      def prepend_space?(node)
        node.at_xpath("preceding::text()[1]").to_s.end_with?('!')
      end
    end

    register :a, A.new
  end
end
