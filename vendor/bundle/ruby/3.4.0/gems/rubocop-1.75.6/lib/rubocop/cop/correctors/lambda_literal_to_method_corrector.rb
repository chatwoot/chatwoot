# frozen_string_literal: true

module RuboCop
  module Cop
    # This class autocorrects lambda literal to method notation.
    class LambdaLiteralToMethodCorrector
      def initialize(block_node)
        @block_node = block_node
        @method     = block_node.send_node
        @arguments  = block_node.arguments
      end

      def call(corrector)
        # Check for unparenthesized args' preceding and trailing whitespaces.
        remove_unparenthesized_whitespace(corrector)

        if block_node.block_type?
          # Avoid correcting to `lambdado` by inserting whitespace
          # if none exists before or after the lambda arguments.
          insert_separating_space(corrector)

          remove_arguments(corrector)
        end

        replace_selector(corrector)

        replace_delimiters(corrector)

        insert_arguments(corrector)
      end

      private

      attr_reader :block_node, :method, :arguments

      def remove_unparenthesized_whitespace(corrector)
        return if arguments.empty? || arguments.parenthesized_call?

        remove_leading_whitespace(corrector)
        remove_trailing_whitespace(corrector)
      end

      def insert_separating_space(corrector)
        return unless needs_separating_space?

        corrector.insert_before(block_begin, ' ')
      end

      def replace_selector(corrector)
        corrector.replace(method, 'lambda')
      end

      def remove_arguments(corrector)
        return if arguments.empty_and_without_delimiters?

        corrector.remove(arguments)
      end

      def insert_arguments(corrector)
        return if arguments.empty?

        arg_str = " |#{lambda_arg_string}|"
        corrector.insert_after(block_node.loc.begin, arg_str)
      end

      def remove_leading_whitespace(corrector)
        corrector.remove_preceding(
          arguments,
          arguments.source_range.begin_pos -
            block_node.send_node.source_range.end_pos
        )
      end

      def remove_trailing_whitespace(corrector)
        size = block_begin.begin_pos - arguments.source_range.end_pos - 1
        corrector.remove_preceding(block_begin, size) if size.positive?
      end

      def replace_delimiters(corrector)
        return if block_node.braces? || !arg_to_unparenthesized_call?

        corrector.insert_after(block_begin, ' ') unless separating_space?

        corrector.replace(block_begin, '{')
        corrector.replace(block_end, '}')
      end

      def lambda_arg_string
        arguments.children.map(&:source).join(', ')
      end

      def needs_separating_space?
        (block_begin.begin_pos == arguments_end_pos &&
          selector_end.end_pos == arguments_begin_pos) ||
          block_begin.begin_pos == selector_end.end_pos
      end

      def arguments_end_pos
        arguments.loc.end&.end_pos
      end

      def arguments_begin_pos
        arguments.loc.begin&.begin_pos
      end

      def block_end
        block_node.loc.end
      end

      def block_begin
        block_node.loc.begin
      end

      def selector_end
        method.loc.selector.end
      end

      def arg_to_unparenthesized_call?
        current_node = block_node

        parent = current_node.parent

        if parent&.pair_type?
          current_node = parent.parent
          parent = current_node.parent
        end

        return false unless parent&.send_type?
        return false if parent.parenthesized_call?

        current_node.sibling_index > 1
      end

      def separating_space?
        block_begin.source_buffer.source[block_begin.begin_pos + 2].match?(/\s/)
      end
    end
  end
end
