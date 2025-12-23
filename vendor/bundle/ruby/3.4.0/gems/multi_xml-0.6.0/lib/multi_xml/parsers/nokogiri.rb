require 'nokogiri' unless defined?(Nokogiri)
require 'multi_xml/parsers/libxml2_parser'

module MultiXml
  module Parsers
    module Nokogiri #:nodoc:
      include Libxml2Parser
      extend self

      def parse_error
        ::Nokogiri::XML::SyntaxError
      end

      def parse(xml)
        doc = ::Nokogiri::XML(xml)
        raise(doc.errors.first) unless doc.errors.empty?
        node_to_hash(doc.root)
      end

    private

      def each_child(node, &block)
        node.children.each(&block)
      end

      def each_attr(node, &block)
        node.attribute_nodes.each(&block)
      end

      def node_name(node)
        node.node_name
      end
    end
  end
end
