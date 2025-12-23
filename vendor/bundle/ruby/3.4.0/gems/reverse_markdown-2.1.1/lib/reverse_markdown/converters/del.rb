module ReverseMarkdown
  module Converters
    class Del < Base
      def convert(node, state = {})
        content = treat_children(node, state.merge(already_crossed_out: true))
        if disabled? || content.strip.empty? || state[:already_crossed_out]
          content
        else
          "~~#{content}~~"
        end
      end

      def enabled?
        ReverseMarkdown.config.github_flavored
      end

      def disabled?
        !enabled?
      end
    end

    register :strike, Del.new
    register :s,      Del.new
    register :del,    Del.new
  end
end
