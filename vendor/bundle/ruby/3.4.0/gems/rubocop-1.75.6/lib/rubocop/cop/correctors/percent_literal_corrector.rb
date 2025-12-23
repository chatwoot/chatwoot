# frozen_string_literal: true

module RuboCop
  module Cop
    # This autocorrects percent literals
    class PercentLiteralCorrector
      include Util

      attr_reader :config, :preferred_delimiters

      def initialize(config, preferred_delimiters)
        @config = config
        @preferred_delimiters = preferred_delimiters
      end

      def correct(corrector, node, char)
        escape = escape_words?(node)
        char = char.upcase if escape
        delimiters = delimiters_for("%#{char}")
        contents = new_contents(node, escape, delimiters)
        wrap_contents(corrector, node, contents, char, delimiters)
      end

      private

      def wrap_contents(corrector, node, contents, char, delimiters)
        corrector.replace(node, "%#{char}#{delimiters[0]}#{contents}#{delimiters[1]}")
      end

      def escape_words?(node)
        node.children.any? { |w| needs_escaping?(w.children[0]) }
      end

      def delimiters_for(type)
        PreferredDelimiters.new(type, config, preferred_delimiters).delimiters
      end

      def new_contents(node, escape, delimiters)
        if node.multiline?
          autocorrect_multiline_words(node, escape, delimiters)
        else
          autocorrect_words(node, escape, delimiters)
        end
      end

      def autocorrect_multiline_words(node, escape, delimiters)
        contents = process_multiline_words(node, escape, delimiters)
        contents << end_content(node.source)
        contents.join
      end

      def autocorrect_words(node, escape, delimiters)
        node.children.map do |word_node|
          fix_escaped_content(word_node, escape, delimiters)
        end.join(' ')
      end

      def process_multiline_words(node, escape, delimiters)
        base_line_num = node.first_line
        prev_line_num = base_line_num
        node.children.map.with_index do |word_node, index|
          line_breaks = line_breaks(word_node, node.source, prev_line_num, base_line_num, index)
          prev_line_num = word_node.last_line
          content = fix_escaped_content(word_node, escape, delimiters)
          line_breaks + content
        end
      end

      def line_breaks(node, source, previous_line_num, base_line_num, node_index)
        source_in_lines = source.split("\n")
        if first_line?(node, previous_line_num)
          node_index.zero? && node.first_line == base_line_num ? '' : ' '
        else
          process_lines(node, previous_line_num, base_line_num, source_in_lines)
        end
      end

      def first_line?(node, previous_line_num)
        node.first_line == previous_line_num
      end

      def process_lines(node, previous_line_num, base_line_num, source_in_lines)
        begin_line_num = previous_line_num - base_line_num + 1
        end_line_num = node.first_line - base_line_num + 1
        lines = source_in_lines[begin_line_num...end_line_num]
        "\n#{lines.join("\n").split(node.source).first || ''}"
      end

      def fix_escaped_content(word_node, escape, delimiters)
        content = +word_node.children.first.to_s
        content = escape_string(content) if escape
        substitute_escaped_delimiters(content, delimiters)
        content
      end

      def substitute_escaped_delimiters(content, delimiters)
        if delimiters.first != delimiters.last
          # With different delimiters (eg. `[]`, `()`), if there are the same
          # number of each, escaping is not necessary
          delimiter_counts = delimiters.each_with_object({}) do |delimiter, counts|
            counts[delimiter] = content.count(delimiter)
          end

          return content if delimiter_counts[delimiters.first] == delimiter_counts[delimiters.last]
        end

        delimiters.each { |delim| content.gsub!(delim, "\\#{delim}") }
      end

      def end_content(source)
        result = /\A(\s*)\]/.match(source.split("\n").last)
        "\n#{result[1]}" if result
      end
    end
  end
end
