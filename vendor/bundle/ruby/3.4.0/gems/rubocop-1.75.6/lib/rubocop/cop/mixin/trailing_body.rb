# frozen_string_literal: true

module RuboCop
  module Cop
    # Common methods shared by TrailingBody cops
    module TrailingBody
      def trailing_body?(node)
        body = node.to_a.reverse[0]
        body && node.multiline? && body_on_first_line?(node, body)
      end

      def body_on_first_line?(node, body)
        same_line?(node, body)
      end

      def first_part_of(body)
        if body.begin_type?
          body.children.first.source_range
        else
          body.source_range
        end
      end
    end
  end
end
