# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for working with heredoc strings.
    module Heredoc
      OPENING_DELIMITER = /(<<[~-]?)['"`]?([^'"`]+)['"`]?/.freeze

      def on_str(node)
        return unless node.heredoc?

        on_heredoc(node)
      end
      alias on_dstr on_str
      alias on_xstr on_str

      def on_heredoc(_node)
        raise NotImplementedError
      end

      private

      def indent_level(str)
        indentations = str.lines.map { |line| line[/^\s*/] }.reject { |line| line.end_with?("\n") }
        indentations.empty? ? 0 : indentations.min_by(&:size).size
      end

      def delimiter_string(node)
        return '' unless (match = node.source.match(OPENING_DELIMITER))

        match.captures[1]
      end

      def heredoc_type(node)
        return '' unless (match = node.source.match(OPENING_DELIMITER))

        match.captures[0]
      end
    end
  end
end
