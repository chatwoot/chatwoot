module Representable::XML
  # Experimental!
  # Best explanation so far: http://books.xmlschemata.org/relaxng/relax-CHP-11-SECT-1.html
  #
  # Note: This module doesn't work with JRuby because Nokogiri uses a completely
  # different implementation in Java which has other requirements that we couldn't fulfil.
  # Please wait for Representable 4 where we replace Nokogiri with Oga.
  module Namespace
    def self.included(includer)
      includer.extend(DSL)
    end

    module DSL
      def namespace(namespace)
        representable_attrs.options[:local_namespace] = namespace
        representable_attrs.options[:namespace_mappings] ||= {}
        representable_attrs.options[:namespace_mappings][namespace] = nil # this might get overwritten via #namespace_def later.
      end

      def namespace_def(mapping)
        namespace_defs.merge!(mapping.invert)
      end

      # :private:
      def namespace_defs
        representable_attrs.options[:namespace_mappings] ||= {}
      end

      def property(name, options={})
        uri = representable_attrs.options[:local_namespace] # per default, a property belongs to the local namespace.
        options[:namespace] ||= uri # don't override if already set.

        # a nested representer is automatically assigned "its" local namespace. It's like saying
        #   property :author, namespace: "http://ns/author" do ... end

        super.tap do |dfn|
          if dfn.typed? # FIXME: ouch, this should be doable with property's API to hook into the creation process.
            dfn.merge!( namespace: dfn.representer_module.representable_attrs.options[:local_namespace] )

            update_namespace_defs!(namespace_defs)
          end
        end
      end

      # :private:
      # super ugly hack
      # recursively injects the namespace_defs into all representers of this tree. will be done better in 4.0.
      def update_namespace_defs!(namespace_defs)
        representable_attrs.each do |dfn|
          dfn.merge!(namespace_defs: namespace_defs) # this only helps with scalars

          if dfn.typed?
            representer = Class.new(dfn.representer_module) # don't pollute classes.
            representer.update_namespace_defs!(namespace_defs)
            dfn.merge!(extend: representer)
          end
        end
      end
    end

    module AsWithNamespace
      def write(doc, fragment, as)
        super(doc, fragment, prefixed(self, as))
      end

      # FIXME: this is shit, the NestedOptions is executed too late here!
      def read(node, as)
        super(node, prefixed(self, as))
      end

      private
      def prefixed(dfn, as)
        uri    = dfn[:namespace] # this is generic behavior and per property
        prefix = dfn[:namespace_defs][uri]
        as     = Namespace::Namespaced(prefix, as)
      end
    end

  # FIXME: some "bug" in Representable's XML doesn't consider the container tag, so we could theoretically pick the
  # wrong namespaced tag here :O
    def from_node(node, options={})
      super
    end

    def to_node(options={})
      local_uri = representable_attrs.options[:local_namespace] # every decorator MUST have a local namespace.
      prefix    = self.class.namespace_defs[local_uri]

      root_tag = [prefix, representation_wrap(options)].compact.join(":")

      options = { wrap: root_tag }.merge(options)

      # TODO: there should be an easier way to pass a set of options to all nested #to_node decorators.
      representable_attrs.keys.each do |property|
        options[property.to_sym] = { show_definition: false, namespaces: options[:namespaces] }
      end

      super(options).tap do |node|
        add_namespace_definitions!(node, self.class.namespace_defs) unless options[:show_definition] == false
      end
    end

    # "Physically" add `xmlns` attributes to `node`.
    def add_namespace_definitions!(node, namespaces)
      namespaces.each do |uri, prefix|
        prefix = prefix.nil? ? nil : prefix.to_s
        node.add_namespace_definition(prefix, uri)
      end
    end

    def self.Namespaced(prefix, name)
      [ prefix, name ].compact.join(":")
    end

    # FIXME: this is a PoC, we need a better API to inject code.
    def representable_map(options, format)
      super.tap do |map|
        map.each { |bin| bin.extend(AsWithNamespace) unless bin.is_a?(Binding::Attribute) }
      end
    end
  end
end
