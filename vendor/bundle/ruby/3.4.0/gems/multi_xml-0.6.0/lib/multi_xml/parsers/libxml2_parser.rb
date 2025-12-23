module MultiXml
  module Parsers
    module Libxml2Parser #:nodoc:
      # Convert XML document to hash
      #
      # node::
      #   The XML node object to convert to a hash.
      #
      # hash::
      #   Hash to merge the converted element into.
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
          if c.element?
            node_to_hash(c, node_hash)
          elsif c.text? || c.cdata?
            node_hash[MultiXml::CONTENT_ROOT] << c.content
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

      # Parse an XML Document IO into a simple hash.
      # xml::
      #   XML Document IO to parse
      def parse(_)
        raise(NotImplementedError.new("inheritor should define #{__method__}"))
      end

    private

      def each_child(*)
        raise(NotImplementedError.new("inheritor should define #{__method__}"))
      end

      def each_attr(*)
        raise(NotImplementedError.new("inheritor should define #{__method__}"))
      end

      def node_name(*)
        raise(NotImplementedError.new("inheritor should define #{__method__}"))
      end
    end
  end
end
