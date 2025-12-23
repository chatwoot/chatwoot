module ReverseMarkdown
  module Converters
    class Strong < Base
      def convert(node, state = {})
        content = treat_children(node, state.merge(already_strong: true))
        if content.strip.empty? || state[:already_strong]
          content
        else
          "#{content[/^\s*/]}**#{content.strip}**#{content[/\s*$/]}"
        end
      end
    end

    register :strong, Strong.new
    register :b,      Strong.new
  end
end
