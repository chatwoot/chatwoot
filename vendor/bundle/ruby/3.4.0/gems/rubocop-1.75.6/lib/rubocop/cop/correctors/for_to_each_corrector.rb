# frozen_string_literal: true

module RuboCop
  module Cop
    # This class autocorrects `for` iteration to `#each` enumeration.
    class ForToEachCorrector
      extend NodePattern::Macros

      CORRECTION = '%<collection>s.each do |%<argument>s|'

      def initialize(for_node)
        @for_node        = for_node
        @variable_node   = for_node.variable
        @collection_node = for_node.collection
      end

      def call(corrector)
        offending_range = for_node.source_range.begin.join(end_range)

        corrector.replace(offending_range, correction)
      end

      private

      attr_reader :for_node, :variable_node, :collection_node

      def correction
        format(CORRECTION, collection: collection_source, argument: variable_node.source)
      end

      def collection_source
        if requires_parentheses?
          "(#{collection_node.source})"
        else
          collection_node.source
        end
      end

      def requires_parentheses?
        return true if collection_node.send_type? && collection_node.operator_method?

        collection_node.range_type? || collection_node.operator_keyword?
      end

      def end_range
        if for_node.do?
          keyword_begin.end
        else
          collection_end.end
        end
      end

      def keyword_begin
        for_node.loc.begin
      end

      def collection_end
        if collection_node.begin_type?
          collection_node.loc.end
        else
          collection_node.source_range
        end
      end
    end
  end
end
