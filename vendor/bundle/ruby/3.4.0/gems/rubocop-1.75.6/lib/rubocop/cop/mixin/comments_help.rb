# frozen_string_literal: true

module RuboCop
  module Cop
    # Help methods for working with nodes containing comments.
    module CommentsHelp
      def source_range_with_comment(node)
        begin_pos = begin_pos_with_comment(node)
        end_pos = end_position_for(node)

        Parser::Source::Range.new(buffer, begin_pos, end_pos)
      end

      def contains_comments?(node)
        comments_in_range(node).any?
      end

      def comments_in_range(node)
        return [] unless node.source_range

        start_line = node.source_range.line
        end_line = find_end_line(node)

        processed_source.each_comment_in_lines(start_line...end_line)
      end

      def comments_contain_disables?(node, cop_name)
        disabled_ranges = processed_source.disabled_line_ranges[cop_name]

        return false unless disabled_ranges

        node_range = node.source_range.line...find_end_line(node)

        disabled_ranges.any? do |disable_range|
          disable_range.cover?(node_range) || node_range.cover?(disable_range)
        end
      end

      private

      def end_position_for(node)
        end_line = buffer.line_for_position(node.source_range.end_pos)
        buffer.line_range(end_line).end_pos
      end

      def begin_pos_with_comment(node)
        first_comment = processed_source.ast_with_comments[node].first

        if first_comment && (first_comment.loc.line < node.loc.line)
          start_line_position(first_comment)
        else
          start_line_position(node)
        end
      end

      def start_line_position(node)
        buffer.line_range(node.loc.line).begin_pos - 1
      end

      def buffer
        processed_source.buffer
      end

      # Returns the end line of a node, which might be a comment and not part of the AST
      # End line is considered either the line at which another node starts, or
      # the line at which the parent node ends.
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def find_end_line(node)
        if node.if_type?
          if node.else?
            node.loc.else.line
          elsif node.ternary?
            node.else_branch.loc.line
          elsif node.elsif?
            node.each_ancestor(:if).find(&:if?).loc.end.line
          elsif node.if? && node.parent && parentheses?(node.parent)
            node.parent.loc.end.line
          end
        elsif node.any_block_type?
          node.loc.end.line
        elsif (next_sibling = node.right_sibling) && next_sibling.is_a?(AST::Node) &&
              next_sibling.source_range
          next_sibling.loc.line
        elsif (parent = node.parent)
          if parent.loc?(:end)
            parent.loc.end.line
          else
            parent.loc.line
          end
        end || node.loc.end.line
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    end
  end
end
