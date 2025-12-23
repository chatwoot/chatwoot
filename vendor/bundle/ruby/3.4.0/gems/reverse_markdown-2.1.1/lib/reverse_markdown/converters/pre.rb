module ReverseMarkdown
  module Converters
    class Pre < Base
      def convert(node, state = {})
        content = treat_children(node, state)
        if ReverseMarkdown.config.github_flavored
          "\n```#{language(node)}\n" << content.strip << "\n```\n"
        else
          "\n\n    " << content.lines.to_a.join("    ") << "\n\n"
        end
      end

      private

      # Override #treat as proposed in https://github.com/xijo/reverse_markdown/pull/69
      def treat(node, state)
        case node.name
        when 'code', 'text'
          node.text.strip
        when 'br'
          "\n"
        else
          super
        end
      end

      def language(node)
        lang = language_from_highlight_class(node)
        lang || language_from_confluence_class(node)
      end

      def language_from_highlight_class(node)
        node.parent['class'].to_s[/highlight-([a-zA-Z0-9]+)/, 1]
      end

      def language_from_confluence_class(node)
        node['class'].to_s[/brush:\s?(:?.*);/, 1]
      end
    end

    register :pre, Pre.new
  end
end
