# frozen_string_literal: true

module RuboCop
  module Cop
    # Checks for code on multiple lines that could be rewritten on a single line
    # without changing semantics or exceeding the `Max` parameter of `Layout/LineLength`.
    module CheckSingleLineSuitability
      def suitable_as_single_line?(node)
        !too_long?(node) &&
          !comment_within?(node) &&
          safe_to_split?(node)
      end

      private

      def too_long?(node)
        lines = processed_source.lines[(node.first_line - 1)...node.last_line]
        to_single_line(lines.join("\n")).length > max_line_length
      end

      def to_single_line(source)
        source
          .gsub(/" *\\\n\s*'/, %q(" + ')) # Double quote, backslash, and then single quote
          .gsub(/' *\\\n\s*"/, %q(' + ")) # Single quote, backslash, and then double quote
          .gsub(/(["']) *\\\n\s*\1/, '')  # Double or single quote, backslash, then same quote
          .gsub(/\n\s*(?=(&)?\.\w)/, '')  # Extra space within method chaining which includes `&.`
          .gsub(/\s*\\?\n\s*/, ' ')       # Any other line break, with or without backslash
      end

      def max_line_length
        config.for_cop('Layout/LineLength')['Max']
      end

      def comment_within?(node)
        comment_line_numbers = processed_source.comments.map { |comment| comment.loc.line }

        comment_line_numbers.any? do |comment_line_number|
          comment_line_number.between?(node.first_line, node.last_line)
        end
      end

      def safe_to_split?(node)
        node.each_descendant(:if, :case, :kwbegin, :any_def).none? &&
          node.each_descendant(:dstr, :str).none? { |n| n.heredoc? || n.value.include?("\n") } &&
          node.each_descendant(:begin, :sym).none? { |b| !b.single_line? }
      end
    end
  end
end
