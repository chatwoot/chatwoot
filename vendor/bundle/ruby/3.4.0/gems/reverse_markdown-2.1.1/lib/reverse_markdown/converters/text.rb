module ReverseMarkdown
  module Converters
    class Text < Base
      def convert(node, options = {})
        if node.text.strip.empty?
          treat_empty(node)
        else
          treat_text(node)
        end
      end

      private

      def treat_empty(node)
        parent = node.parent.name.to_sym
        if [:ol, :ul].include?(parent)  # Otherwise the identation is broken
          ''
        elsif node.text == ' '          # Regular whitespace text node
          ' '
        else
          ''
        end
      end

      def treat_text(node)
        text = node.text
        text = preserve_nbsp(text)
        text = remove_border_newlines(text)
        text = remove_inner_newlines(text)
        text = escape_keychars(text)

        text = preserve_keychars_within_backticks(text)
        text = preserve_tags(text)

        text
      end

      def preserve_nbsp(text)
        text.gsub(/\u00A0/, "&nbsp;")
      end

      def preserve_tags(text)
        text.gsub(/[<>]/, '>' => '\>', '<' => '\<')
      end

      def remove_border_newlines(text)
        text.gsub(/\A\n+/, '').gsub(/\n+\z/, '')
      end

      def remove_inner_newlines(text)
        text.tr("\r\n\t", ' ').squeeze(' ')
      end

      def preserve_keychars_within_backticks(text)
        text.gsub(/`.*?`/) do |match|
          match.gsub('\_', '_').gsub('\*', '*')
        end
      end
    end

    register :text, Text.new
  end
end
