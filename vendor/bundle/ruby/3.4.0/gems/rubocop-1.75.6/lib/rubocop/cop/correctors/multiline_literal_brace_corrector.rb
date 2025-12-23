# frozen_string_literal: true

module RuboCop
  module Cop
    # Autocorrection logic for the closing brace of a literal either
    # on the same line as the last contained elements, or a new line.
    class MultilineLiteralBraceCorrector
      include MultilineLiteralBraceLayout
      include RangeHelp

      def self.correct(corrector, node, processed_source)
        new(corrector, node, processed_source).call
      end

      def initialize(corrector, node, processed_source)
        @corrector = corrector
        @node = node
        @processed_source = processed_source
      end

      def call
        if closing_brace_on_same_line?(node)
          correct_same_line_brace(corrector)
        else
          # When a comment immediately before the closing brace gets in the
          # way of an easy correction, the offense is reported but not auto-
          # corrected. The user must handle the delicate decision of where to
          # put the comment.
          return if new_line_needed_before_closing_brace?(node)

          end_range = last_element_range_with_trailing_comma(node).end

          correct_next_line_brace(corrector, end_range)
          correct_heredoc_argument_method_chain(corrector, end_range)
        end
      end

      private

      attr_reader :corrector, :node, :processed_source

      def correct_same_line_brace(corrector)
        corrector.insert_before(node.loc.end, "\n")
      end

      def correct_next_line_brace(corrector, end_range)
        corrector.remove(range_with_surrounding_space(node.loc.end, side: :left))
        corrector.insert_before(end_range, content_if_comment_present(corrector, node))
      end

      def correct_heredoc_argument_method_chain(corrector, end_range)
        return unless (parent = node.parent)
        return unless use_heredoc_argument_method_chain?(parent)

        chained_method = range_between(parent.loc.dot.begin_pos, parent.source_range.end_pos)

        corrector.remove(chained_method)
        corrector.insert_after(end_range, chained_method.source)
      end

      def content_if_comment_present(corrector, node)
        range = range_with_surrounding_space(
          children(node).last.source_range,
          side: :right
        ).end.resize(1)
        if range.source == '#'
          select_content_to_be_inserted_after_last_element(corrector, node)
        else
          node.loc.end.source
        end
      end

      def use_heredoc_argument_method_chain?(parent)
        return false unless node.respond_to?(:first_argument)
        return false unless (first_argument = node.first_argument)

        parent.call_type? && first_argument.str_type? && first_argument.heredoc?
      end

      def select_content_to_be_inserted_after_last_element(corrector, node)
        range = range_between(
          node.loc.end.begin_pos,
          range_by_whole_lines(node.source_range).end.end_pos
        )

        remove_trailing_content_of_comment(corrector, range)
        range.source
      end

      def remove_trailing_content_of_comment(corrector, range)
        corrector.remove(range)
      end

      def last_element_range_with_trailing_comma(node)
        trailing_comma_range = last_element_trailing_comma_range(node)
        if trailing_comma_range
          children(node).last.source_range.join(trailing_comma_range)
        else
          children(node).last.source_range
        end
      end

      def last_element_trailing_comma_range(node)
        range = range_with_surrounding_space(
          children(node).last.source_range,
          side: :right
        ).end.resize(1)

        range.source == ',' ? range : nil
      end
    end
  end
end
