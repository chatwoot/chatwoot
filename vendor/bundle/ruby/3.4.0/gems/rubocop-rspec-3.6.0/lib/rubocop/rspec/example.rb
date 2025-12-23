# frozen_string_literal: true

module RuboCop
  module RSpec
    # Wrapper for RSpec examples
    class Example < Concept
      # @!method extract_doc_string(node)
      def_node_matcher :extract_doc_string,     '(send _ _ $_ ...)'

      # @!method extract_metadata(node)
      def_node_matcher :extract_metadata,       '(send _ _ _ $...)'

      # @!method extract_implementation(node)
      def_node_matcher :extract_implementation, '(block send args $_)'

      def doc_string
        extract_doc_string(definition)
      end

      def metadata
        extract_metadata(definition)
      end

      def implementation
        extract_implementation(node)
      end

      def definition
        if node.send_type?
          node
        else
          node.send_node
        end
      end
    end
  end
end
