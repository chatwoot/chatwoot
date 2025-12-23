# frozen_string_literal: true

module RuboCop
  module Cop
    # Handles adding and checking ignored nodes.
    module IgnoredNode
      def ignore_node(node)
        ignored_nodes << node
      end

      def part_of_ignored_node?(node)
        ignored_nodes.map(&:loc).any? do |ignored_loc|
          next false if ignored_loc.expression.begin_pos > node.source_range.begin_pos

          ignored_end_pos = if ignored_loc.respond_to?(:heredoc_body)
                              ignored_loc.heredoc_end.end_pos
                            else
                              ignored_loc.expression.end_pos
                            end
          ignored_end_pos >= node.source_range.end_pos
        end
      end

      def ignored_node?(node)
        # Same object found in array?
        ignored_nodes.any? { |n| n.equal?(node) }
      end

      private

      def ignored_nodes
        @ignored_nodes ||= []
      end
    end
  end
end
