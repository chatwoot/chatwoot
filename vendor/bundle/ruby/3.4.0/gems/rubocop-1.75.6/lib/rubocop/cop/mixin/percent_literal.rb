# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for handling percent literals.
    module PercentLiteral
      include RangeHelp

      private

      def percent_literal?(node)
        return false unless (begin_source = begin_source(node))

        begin_source.start_with?('%')
      end

      def process(node, *types)
        return unless percent_literal?(node) && types.include?(type(node))

        on_percent_literal(node)
      end

      def begin_source(node)
        node.loc.begin.source if node.loc?(:begin)
      end

      def type(node)
        node.loc.begin.source[0..-2]
      end
    end
  end
end
