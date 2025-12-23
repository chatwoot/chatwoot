require 'representable/binding'

module Representable
  module XML
    module_function def Node(document, name, attributes={})
      node = Nokogiri::XML::Node.new(name.to_s, document) # Java::OrgW3cDom::DOMException: NAMESPACE_ERR: An attempt is made to create or change an object in a way which is incorrect with regard to namespaces.

      attributes.each { |k, v| node[k] = v } # TODO: benchmark.
      node
    end

    class Binding < Representable::Binding
      def self.build_for(definition)
        return Collection.new(definition)      if definition.array?
        return Hash.new(definition)            if definition.hash? and not definition[:use_attributes] # FIXME: hate this.
        return AttributeHash.new(definition)   if definition.hash? and definition[:use_attributes]
        return Attribute.new(definition)       if definition[:attribute]
        return Content.new(definition)         if definition[:content]

        new(definition)
      end

      def write(parent, fragments, as)
        wrap_node = parent

        if wrap = self[:wrap]
          parent << wrap_node = XML::Node(parent.document, wrap)
        end

        wrap_node << serialize_for(fragments, parent, as)
      end

      def read(node, as)
        nodes = find_nodes(node, as)
        return FragmentNotFound if nodes.size == 0 # TODO: write dedicated test!

        deserialize_from(nodes)
      end

      # Creates wrapped node for the property.
      def serialize_for(value, parent, as)
        node = XML::Node(parent.document, as) # node doesn't have attr="" attributes!!!
        serialize_node(node, value, as)
      end

      def serialize_node(node, value, as)
        if typed?
          value.name = as if as != self[:name]
          return value
        end

        node.content = value
        node
      end

      def deserialize_from(nodes)
        content_for(nodes.first)
      end

      # DISCUSS: why is this public?
      def serialize_method
        :to_node
      end

      def deserialize_method
        :from_node
      end

    private
      def find_nodes(doc, as)
        selector  = as
        selector  = "#{self[:wrap]}/#{as}" if self[:wrap]
        doc.xpath(selector) # nodes
      end

      def content_for(node) # TODO: move this into a ScalarDecorator.
        return node if typed?

        node.content
      end


      class Collection < self
        include Representable::Binding::Collection

        def serialize_for(value, parent, as)
          # return NodeSet so << works.
          set_for(parent, value.collect { |item| super(item, parent, as) })
        end

        def deserialize_from(nodes)
          content_nodes = nodes.collect do |item| # TODO: move this to Node?
            content_for(item)
          end

          content_nodes
        end

      private
        def set_for(parent, nodes)
          Nokogiri::XML::NodeSet.new(parent.document, nodes)
        end
      end


      class Hash < Collection
        def serialize_for(value, parent, as)
          set_for(parent, value.collect do |k, v|
            node = XML::Node(parent.document, k)
            serialize_node(node, v, as)
          end)
        end

        def deserialize_from(nodes)
          hash = {}
          nodes.children.each do |node|
            hash[node.name] = content_for node
          end

          hash
        end
      end

      class AttributeHash < Collection
        # DISCUSS: use AttributeBinding here?
        def write(parent, value, as)  # DISCUSS: is it correct overriding #write here?
          value.collect do |k, v|
            parent[k] = v.to_s
          end
          parent
        end

        # FIXME: this is not tested!
        def deserialize_from(node)
          HashDeserializer.new(self).deserialize(node)
        end
      end


      # Represents a tag attribute. Currently this only works on the top-level tag.
      class Attribute < self
        def read(node, as)
          node[as]
        end

        def serialize_for(value, parent, as)
          parent[as] = value.to_s
        end

        def write(parent, value, as)
          serialize_for(value, parent, as)
        end
      end

      # Represents tag content.
      class Content < self
        def read(node, as)
          node.content
        end

        def serialize_for(value, parent)
          parent.content = value.to_s
        end

        def write(parent, value, as)
          serialize_for(value, parent)
        end
      end
    end # Binding
  end
end
