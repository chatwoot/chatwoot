# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for handling percent arrays.
    module PercentArray
      private

      # Ruby does not allow percent arrays in an ambiguous block context.
      #
      # @example
      #
      #   foo %i[bar baz] { qux }
      def invalid_percent_array_context?(node)
        parent = node.parent

        parent&.send_type? && parent.arguments.include?(node) &&
          !parent.parenthesized? && parent.block_literal?
      end

      # Override to determine values that are invalid in a percent array
      def invalid_percent_array_contents?(_node)
        false
      end

      def allowed_bracket_array?(node)
        comments_in_array?(node) || below_array_length?(node) ||
          invalid_percent_array_context?(node)
      end

      def comments_in_array?(node)
        line_span = node.source_range.first_line...node.source_range.last_line
        processed_source.each_comment_in_lines(line_span).any?
      end

      def check_percent_array(node)
        array_style_detected(:percent, node.values.size)

        brackets_required = invalid_percent_array_contents?(node)
        return unless style == :brackets || brackets_required

        # If in percent style but brackets are required due to
        # string content, the file should be excluded in auto-gen-config
        no_acceptable_style! if brackets_required

        bracketed_array = build_bracketed_array(node)
        message = build_message_for_bracketed_array(bracketed_array)

        add_offense(node, message: message) do |corrector|
          corrector.replace(node, bracketed_array)
        end
      end

      # @param [String] preferred_array_code
      # @return [String]
      def build_message_for_bracketed_array(preferred_array_code)
        format(
          self.class::ARRAY_MSG,
          prefer: if preferred_array_code.include?("\n")
                    'an array literal `[...]`'
                  else
                    "`#{preferred_array_code}`"
                  end
        )
      end

      def check_bracketed_array(node, literal_prefix)
        return if allowed_bracket_array?(node)

        array_style_detected(:brackets, node.values.size)

        return unless style == :percent

        add_offense(node, message: self.class::PERCENT_MSG) do |corrector|
          percent_literal_corrector = PercentLiteralCorrector.new(@config, @preferred_delimiters)
          percent_literal_corrector.correct(corrector, node, literal_prefix)
        end
      end

      # @param [RuboCop::AST::ArrayNode] node
      # @param [Array<String>] elements
      # @return [String]
      def build_bracketed_array_with_appropriate_whitespace(elements:, node:)
        [
          '[',
          whitespace_leading(node),
          elements.join(",#{whitespace_between(node)}"),
          whitespace_trailing(node),
          ']'
        ].join
      end

      # Provides whitespace between elements for building a bracketed array.
      #   %w[  a   b   c    ]
      #         ^^^
      # @param [RuboCop::AST::ArrayNode] node
      # @return [String]
      def whitespace_between(node)
        if node.children.length >= 2
          node.children[0].source_range.end.join(node.children[1].source_range.begin).source
        else
          ' '
        end
      end

      # Provides leading whitespace for building a bracketed array.
      #   %w[  a   b   c    ]
      #      ^^
      # @param [RuboCop::AST::ArrayNode] node
      # @return [String]
      def whitespace_leading(node)
        node.loc.begin.end.join(node.children[0].source_range.begin).source
      end

      # Provides trailing whitespace for building a bracketed array.
      #   %w[  a   b   c    ]
      #                 ^^^^
      # @param [RuboCop::AST::ArrayNode] node
      # @return [String]
      def whitespace_trailing(node)
        node.children[-1].source_range.end.join(node.loc.end.begin).source
      end
    end
  end
end
