require 'libxml' unless defined?(LibXML)
require 'multi_xml/parsers/libxml2_parser'

module MultiXml
  module Parsers
    module Libxml #:nodoc:
      include Libxml2Parser
      extend self

      def parse_error
        ::LibXML::XML::Error
      end

      def parse(xml)
        node_to_hash(LibXML::XML::Parser.io(xml).parse.root)
      end

    private

      def each_child(node, &block)
        node.each_child(&block)
      end

      def each_attr(node, &block)
        node.each_attr(&block)
      end

      def node_name(node)
        node.name
      end
    end
  end
end
