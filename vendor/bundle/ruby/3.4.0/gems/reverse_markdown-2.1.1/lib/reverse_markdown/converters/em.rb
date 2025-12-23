module ReverseMarkdown
  module Converters
    class Em < Base
      def convert(node, state = {})
        content = treat_children(node, state.merge(already_italic: true))
        if content.strip.empty? || state[:already_italic]
          content
        else
          "#{content[/^\s*/]}_#{content.strip}_#{content[/\s*$/]}"
        end
      end
    end

    register :em, Em.new
    register :i,  Em.new
  end
end
