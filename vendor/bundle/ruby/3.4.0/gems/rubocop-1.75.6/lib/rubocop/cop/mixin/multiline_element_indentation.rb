# frozen_string_literal: true

module RuboCop
  module Cop
    # Common code for indenting the first elements in multiline
    # array literals, hash literals, and method definitions.
    module MultilineElementIndentation
      private

      def each_argument_node(node, type)
        left_parenthesis = node.loc.begin

        return unless left_parenthesis

        node.arguments.each do |arg|
          on_node(type, arg, :send) do |type_node|
            left_brace = type_node.loc.begin
            if left_brace && same_line?(left_brace, left_parenthesis)
              yield type_node, left_parenthesis
              ignore_node(type_node)
            end
          end
        end
      end

      def check_first(first, left_brace, left_parenthesis, offset)
        actual_column = first.source_range.column

        indent_base_column, indent_base_type = indent_base(left_brace, first, left_parenthesis)
        expected_column = indent_base_column + configured_indentation_width + offset

        @column_delta = expected_column - actual_column
        styles = detected_styles(actual_column, offset, left_parenthesis, left_brace)

        if @column_delta.zero?
          check_expected_style(styles)
        else
          incorrect_style_detected(styles, first, indent_base_type)
        end
      end

      def check_expected_style(styles)
        if styles.size > 1
          ambiguous_style_detected(*styles)
        else
          correct_style_detected
        end
      end

      def indent_base(left_brace, first, left_parenthesis)
        return [left_brace.column, :left_brace_or_bracket] if style == brace_alignment_style

        pair = hash_pair_where_value_beginning_with(left_brace, first)
        if pair && key_and_value_begin_on_same_line?(pair) &&
           right_sibling_begins_on_subsequent_line?(pair)
          return [pair.loc.column, :parent_hash_key]
        end

        if left_parenthesis && style == :special_inside_parentheses
          return [left_parenthesis.column + 1, :first_column_after_left_parenthesis]
        end

        [left_brace.source_line =~ /\S/, :start_of_line]
      end

      def hash_pair_where_value_beginning_with(left_brace, first)
        return unless first && first.parent.loc.begin == left_brace

        first.parent&.parent&.pair_type? ? first.parent.parent : nil
      end

      def key_and_value_begin_on_same_line?(pair)
        same_line?(pair.key, pair.value)
      end

      def right_sibling_begins_on_subsequent_line?(pair)
        pair.right_sibling && (pair.last_line < pair.right_sibling.first_line)
      end

      def detected_styles(actual_column, offset, left_parenthesis, left_brace)
        base_column = actual_column - configured_indentation_width - offset
        detected_styles_for_column(base_column, left_parenthesis, left_brace)
      end

      def detected_styles_for_column(column, left_parenthesis, left_brace)
        styles = []
        if column == (left_brace.source_line =~ /\S/)
          styles << :consistent
          styles << :special_inside_parentheses unless left_parenthesis
        end
        if left_parenthesis && column == left_parenthesis.column + 1
          styles << :special_inside_parentheses
        end
        styles << brace_alignment_style if column == left_brace.column
        styles
      end

      def incorrect_style_detected(styles, first, base_column_type)
        msg = message(base_description(base_column_type))

        add_offense(first, message: msg) do |corrector|
          autocorrect(corrector, first)

          ambiguous_style_detected(*styles)
        end
      end
    end
  end
end
