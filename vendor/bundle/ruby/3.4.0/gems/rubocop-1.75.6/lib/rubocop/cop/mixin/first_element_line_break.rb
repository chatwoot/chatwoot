# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking for a line break before the first
    # element in a multi-line collection.
    module FirstElementLineBreak
      private

      def check_method_line_break(node, children, ignore_last: false)
        return if children.empty?

        return unless method_uses_parens?(node, children.first)

        check_children_line_break(node, children, ignore_last: ignore_last)
      end

      def method_uses_parens?(node, limit)
        source = node.source_range.source_line[0...limit.loc.column]
        /\s*\(\s*$/.match?(source)
      end

      def check_children_line_break(node, children, start = node, ignore_last: false)
        return if children.empty?

        line = start.first_line

        min = first_by_line(children)
        return if line != min.first_line

        max_line = last_line(children, ignore_last: ignore_last)
        return if line == max_line

        add_offense(min) { |corrector| EmptyLineCorrector.insert_before(corrector, min) }
      end

      def first_by_line(nodes)
        nodes.min_by(&:first_line)
      end

      def last_line(nodes, ignore_last:)
        if ignore_last
          nodes.map(&:first_line)
        else
          nodes.map(&:last_line)
        end.max
      end
    end
  end
end
