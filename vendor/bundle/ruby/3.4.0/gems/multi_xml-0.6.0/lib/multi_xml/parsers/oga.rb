require 'oga' unless defined?(Oga)
require 'multi_xml/parsers/libxml2_parser'

module MultiXml
  module Parsers
    module Oga #:nodoc:
      include Libxml2Parser
      extend self

      def parse_error
        LL::ParserError
      end

      def parse(io)
        document = ::Oga.parse_xml(io)
        node_to_hash(document.children[0])
      end

      def node_to_hash(node, hash = {}) # rubocop:disable AbcSize, CyclomaticComplexity, MethodLength, PerceivedComplexity
        node_hash = {MultiXml::CONTENT_ROOT => ''}

        name = node_name(node)

        # Insert node hash into parent hash correctly.
        case hash[name]
        when Array
          hash[name] << node_hash
        when Hash
          hash[name] = [hash[name], node_hash]
        when NilClass
          hash[name] = node_hash
        end

        # Handle child elements
        each_child(node) do |c|
          if c.is_a?(::Oga::XML::Element)
            node_to_hash(c, node_hash)
          elsif c.is_a?(::Oga::XML::Text) || c.is_a?(::Oga::XML::Cdata)
            node_hash[MultiXml::CONTENT_ROOT] << c.text
          end
        end

        # Remove content node if it is empty
        if node_hash[MultiXml::CONTENT_ROOT].strip.empty?
          node_hash.delete(MultiXml::CONTENT_ROOT)
        end

        # Handle attributes
        each_attr(node) do |a|
          key = node_name(a)
          v = node_hash[key]
          node_hash[key] = (v ? [a.value, v] : a.value)
        end

        hash
      end

    private

      def each_child(node, &block)
        node.children.each(&block)
      end

      def each_attr(node, &block)
        node.attributes.each(&block)
      end

      def node_name(node)
        node.name
      end
    end # Oga
  end # Parsers
end # MultiXml
