# coding: utf-8
# frozen_string_literal: true

require "pathname"

module Nokogiri
  module XML
    # Nokogiri::XML::Document is the main entry point for dealing with \XML documents. The Document
    # is created by parsing \XML content from a String or an IO object. See
    # Nokogiri::XML::Document.parse for more information on parsing.
    #
    # Document inherits a great deal of functionality from its superclass Nokogiri::XML::Node, so
    # please read that class's documentation as well.
    class Document < Nokogiri::XML::Node
      # See http://www.w3.org/TR/REC-xml-names/#ns-decl for more details. Note that we're not
      # attempting to handle unicode characters partly because libxml2 doesn't handle unicode
      # characters in NCNAMEs.
      NCNAME_START_CHAR = "A-Za-z_"
      NCNAME_CHAR       = NCNAME_START_CHAR + "\\-\\.0-9"
      NCNAME_RE         = /^xmlns(?::([#{NCNAME_START_CHAR}][#{NCNAME_CHAR}]*))?$/

      OBJECT_DUP_METHOD = Object.instance_method(:dup)
      OBJECT_CLONE_METHOD = Object.instance_method(:clone)
      private_constant :OBJECT_DUP_METHOD, :OBJECT_CLONE_METHOD

      class << self
        # call-seq:
        #   parse(input) { |options| ... } => Nokogiri::XML::Document
        #   parse(input, url:, encoding:, options:) => Nokogiri::XML::Document
        #
        # Parse \XML input from a String or IO object, and return a new XML::Document.
        #
        # 🛡 By default, Nokogiri treats documents as untrusted, and so does not attempt to load DTDs
        # or access the network. See Nokogiri::XML::ParseOptions for a complete list of options; and
        # that module's DEFAULT_XML constant for what's set (and not set) by default.
        #
        # [Required Parameters]
        # - +input+ (String | IO) The content to be parsed.
        #
        # [Optional Keyword Arguments]
        # - +url:+ (String) The base URI for this document.
        #
        # - +encoding:+ (String) The name of the encoding that should be used when processing the
        #   document. When not provided, the encoding will be determined based on the document
        #   content.
        #
        # - +options:+ (Nokogiri::XML::ParseOptions) Configuration object that determines some
        #   behaviors during parsing. See ParseOptions for more information. The default value is
        #   +ParseOptions::DEFAULT_XML+.
        #
        # [Yields]
        #   If a block is given, a Nokogiri::XML::ParseOptions object is yielded to the block which
        #   can be configured before parsing. See Nokogiri::XML::ParseOptions for more information.
        #
        # [Returns] Nokogiri::XML::Document
        def parse(
          string_or_io,
          url_ = nil, encoding_ = nil, options_ = XML::ParseOptions::DEFAULT_XML,
          url: url_, encoding: encoding_, options: options_
        )
          options = Nokogiri::XML::ParseOptions.new(options) if Integer === options
          yield options if block_given?

          url ||= string_or_io.respond_to?(:path) ? string_or_io.path : nil

          if empty_doc?(string_or_io)
            if options.strict?
              raise Nokogiri::XML::SyntaxError, "Empty document"
            else
              return encoding ? new.tap { |i| i.encoding = encoding } : new
            end
          end

          doc = if string_or_io.respond_to?(:read)
            # TODO: should we instead check for respond_to?(:to_path) ?
            if string_or_io.is_a?(Pathname)
              # resolve the Pathname to the file and open it as an IO object, see #2110
              string_or_io = string_or_io.expand_path.open
              url ||= string_or_io.path
            end

            read_io(string_or_io, url, encoding, options.to_i)
          else
            # read_memory pukes on empty docs
            read_memory(string_or_io, url, encoding, options.to_i)
          end

          # do xinclude processing
          doc.do_xinclude(options) if options.xinclude?

          doc
        end

        private

        def empty_doc?(string_or_io)
          string_or_io.nil? ||
            (string_or_io.respond_to?(:empty?) && string_or_io.empty?) ||
            (string_or_io.respond_to?(:eof?) && string_or_io.eof?)
        end
      end

      ##
      # :singleton-method: wrap
      # :call-seq: wrap(java_document) → Nokogiri::XML::Document
      #
      # ⚠ This method is only available when running JRuby.
      #
      # Create a Document using an existing Java DOM document object.
      #
      # The returned Document shares the same underlying data structure as the Java object, so
      # changes in one are reflected in the other.
      #
      # [Parameters]
      # - `java_document` (Java::OrgW3cDom::Document)
      #   (The class `Java::OrgW3cDom::Document` is also accessible as `org.w3c.dom.Document`.)
      #
      # [Returns] Nokogiri::XML::Document
      #
      # See also \#to_java

      # :method: to_java
      # :call-seq: to_java() → Java::OrgW3cDom::Document
      #
      # ⚠ This method is only available when running JRuby.
      #
      # Returns the underlying Java DOM document object for this document.
      #
      # The returned Java object shares the same underlying data structure as this document, so
      # changes in one are reflected in the other.
      #
      # [Returns]
      #   Java::OrgW3cDom::Document
      #   (The class `Java::OrgW3cDom::Document` is also accessible as `org.w3c.dom.Document`.)
      #
      # See also Document.wrap

      # The errors found while parsing a document.
      #
      # [Returns] Array<Nokogiri::XML::SyntaxError>
      attr_accessor :errors

      # When `true`, reparented elements without a namespace will inherit their new parent's
      # namespace (if one exists). Defaults to `false`.
      #
      # [Returns] Boolean
      #
      # *Example:* Default behavior of namespace inheritance
      #
      #   xml = <<~EOF
      #           <root xmlns:foo="http://nokogiri.org/default_ns/test/foo">
      #             <foo:parent>
      #             </foo:parent>
      #           </root>
      #         EOF
      #   doc = Nokogiri::XML(xml)
      #   parent = doc.at_xpath("//foo:parent", "foo" => "http://nokogiri.org/default_ns/test/foo")
      #   parent.add_child("<child></child>")
      #   doc.to_xml
      #   # => <?xml version="1.0"?>
      #   #    <root xmlns:foo="http://nokogiri.org/default_ns/test/foo">
      #   #      <foo:parent>
      #   #        <child/>
      #   #      </foo:parent>
      #   #    </root>
      #
      # *Example:* Setting namespace inheritance to `true`
      #
      #   xml = <<~EOF
      #           <root xmlns:foo="http://nokogiri.org/default_ns/test/foo">
      #             <foo:parent>
      #             </foo:parent>
      #           </root>
      #         EOF
      #   doc = Nokogiri::XML(xml)
      #   doc.namespace_inheritance = true
      #   parent = doc.at_xpath("//foo:parent", "foo" => "http://nokogiri.org/default_ns/test/foo")
      #   parent.add_child("<child></child>")
      #   doc.to_xml
      #   # => <?xml version="1.0"?>
      #   #    <root xmlns:foo="http://nokogiri.org/default_ns/test/foo">
      #   #      <foo:parent>
      #   #        <foo:child/>
      #   #      </foo:parent>
      #   #    </root>
      #
      # Since v1.12.4
      attr_accessor :namespace_inheritance

      def initialize(*args) # :nodoc: # rubocop:disable Lint/MissingSuper
        @errors     = []
        @decorators = nil
        @namespace_inheritance = false
      end

      #
      # :call-seq:
      #   dup → Nokogiri::XML::Document
      #   dup(level) → Nokogiri::XML::Document
      #
      # Duplicate this node.
      #
      # [Parameters]
      # - +level+ (optional Integer). 0 is a shallow copy, 1 (the default) is a deep copy.
      # [Returns] The new Nokogiri::XML::Document
      #
      def dup(level = 1)
        copy = OBJECT_DUP_METHOD.bind_call(self)
        copy.initialize_copy_with_args(self, level)
      end

      #
      # :call-seq:
      #   clone → Nokogiri::XML::Document
      #   clone(level) → Nokogiri::XML::Document
      #
      # Clone this node.
      #
      # [Parameters]
      # - +level+ (optional Integer). 0 is a shallow copy, 1 (the default) is a deep copy.
      # [Returns] The new Nokogiri::XML::Document
      #
      def clone(level = 1)
        copy = OBJECT_CLONE_METHOD.bind_call(self)
        copy.initialize_copy_with_args(self, level)
      end

      # :call-seq:
      #   create_element(name, *contents_or_attrs, &block) → Nokogiri::XML::Element
      #
      # Create a new Element with `name` belonging to this document, optionally setting contents or
      # attributes.
      #
      # This method is _not_ the most user-friendly option if your intention is to add a node to the
      # document tree. Prefer one of the Nokogiri::XML::Node methods like Node#add_child,
      # Node#add_next_sibling, Node#replace, etc. which will both create an element (or subtree) and
      # place it in the document tree.
      #
      # Arguments may be passed to initialize the element:
      #
      # - a Hash argument will be used to set attributes
      # - a non-Hash object that responds to \#to_s will be used to set the new node's contents
      #
      # A block may be passed to mutate the node.
      #
      # [Parameters]
      # - `name` (String)
      # - `contents_or_attrs` (\#to_s, Hash)
      # [Yields] `node` (Nokogiri::XML::Element)
      # [Returns] Nokogiri::XML::Element
      #
      # *Example:* An empty element without attributes
      #
      #   doc.create_element("div")
      #   # => <div></div>
      #
      # *Example:* An element with contents
      #
      #   doc.create_element("div", "contents")
      #   # => <div>contents</div>
      #
      # *Example:* An element with attributes
      #
      #   doc.create_element("div", {"class" => "container"})
      #   # => <div class='container'></div>
      #
      # *Example:* An element with contents and attributes
      #
      #   doc.create_element("div", "contents", {"class" => "container"})
      #   # => <div class='container'>contents</div>
      #
      # *Example:* Passing a block to mutate the element
      #
      #   doc.create_element("div") { |node| node["class"] = "blue" if before_noon? }
      #
      def create_element(name, *contents_or_attrs, &block)
        elm = Nokogiri::XML::Element.new(name, self, &block)
        contents_or_attrs.each do |arg|
          case arg
          when Hash
            arg.each do |k, v|
              key = k.to_s
              if key =~ NCNAME_RE
                ns_name = Regexp.last_match(1)
                elm.add_namespace_definition(ns_name, v)
              else
                elm[k.to_s] = v.to_s
              end
            end
          else
            elm.content = arg
          end
        end
        if (ns = elm.namespace_definitions.find { |n| n.prefix.nil? || (n.prefix == "") })
          elm.namespace = ns
        end
        elm
      end

      # Create a Text Node with +string+
      def create_text_node(string, &block)
        Nokogiri::XML::Text.new(string.to_s, self, &block)
      end

      # Create a CDATA Node containing +string+
      def create_cdata(string, &block)
        Nokogiri::XML::CDATA.new(self, string.to_s, &block)
      end

      # Create a Comment Node containing +string+
      def create_comment(string, &block)
        Nokogiri::XML::Comment.new(self, string.to_s, &block)
      end

      # The name of this document.  Always returns "document"
      def name
        "document"
      end

      # A reference to +self+
      def document
        self
      end

      # :call-seq:
      #   collect_namespaces() → Hash<String(Namespace#prefix) ⇒ String(Namespace#href)>
      #
      # Recursively get all namespaces from this node and its subtree and return them as a
      # hash.
      #
      # ⚠ This method will not handle duplicate namespace prefixes, since the return value is a hash.
      #
      # Note that this method does an xpath lookup for nodes with namespaces, and as a result the
      # order (and which duplicate prefix "wins") may be dependent on the implementation of the
      # underlying XML library.
      #
      # *Example:* Basic usage
      #
      # Given this document:
      #
      #   <root xmlns="default" xmlns:foo="bar">
      #     <bar xmlns:hello="world" />
      #   </root>
      #
      # This method will return:
      #
      #   {"xmlns:foo"=>"bar", "xmlns"=>"default", "xmlns:hello"=>"world"}
      #
      # *Example:* Duplicate prefixes
      #
      # Given this document:
      #
      #   <root xmlns:foo="bar">
      #     <bar xmlns:foo="baz" />
      #   </root>
      #
      # The hash returned will be something like:
      #
      #   {"xmlns:foo" => "baz"}
      #
      def collect_namespaces
        xpath("//namespace::*").each_with_object({}) do |ns, hash|
          hash[["xmlns", ns.prefix].compact.join(":")] = ns.href if ns.prefix != "xml"
        end
      end

      # Get the list of decorators given +key+
      def decorators(key)
        @decorators ||= {}
        @decorators[key] ||= []
      end

      ##
      # Validate this Document against its DTD.  Returns a list of errors on
      # the document or +nil+ when there is no DTD.
      def validate
        return unless internal_subset

        internal_subset.validate(self)
      end

      ##
      # Explore a document with shortcut methods. See Nokogiri::Slop for details.
      #
      # Note that any nodes that have been instantiated before #slop!
      # is called will not be decorated with sloppy behavior. So, if you're in
      # irb, the preferred idiom is:
      #
      #   irb> doc = Nokogiri::Slop my_markup
      #
      # and not
      #
      #   irb> doc = Nokogiri::HTML my_markup
      #   ... followed by irb's implicit inspect (and therefore instantiation of every node) ...
      #   irb> doc.slop!
      #   ... which does absolutely nothing.
      #
      def slop!
        unless decorators(XML::Node).include?(Nokogiri::Decorators::Slop)
          decorators(XML::Node) << Nokogiri::Decorators::Slop
          decorate!
        end

        self
      end

      ##
      # Apply any decorators to +node+
      def decorate(node)
        return unless @decorators

        @decorators.each do |klass, list|
          next unless node.is_a?(klass)

          list.each { |mod| node.extend(mod) }
        end
      end

      alias_method :to_xml, :serialize

      # Get the hash of namespaces on the root Nokogiri::XML::Node
      def namespaces
        root ? root.namespaces : {}
      end

      ##
      # Create a Nokogiri::XML::DocumentFragment from +tags+
      # Returns an empty fragment if +tags+ is nil.
      def fragment(tags = nil)
        DocumentFragment.new(self, tags, root)
      end

      undef_method :swap, :parent, :namespace, :default_namespace=
      undef_method :add_namespace_definition, :attributes
      undef_method :namespace_definitions, :line, :add_namespace

      def add_child(node_or_tags)
        raise "A document may not have multiple root nodes." if (root && root.name != "nokogiri_text_wrapper") && !(node_or_tags.comment? || node_or_tags.processing_instruction?)

        node_or_tags = coerce(node_or_tags)
        if node_or_tags.is_a?(XML::NodeSet)
          raise "A document may not have multiple root nodes." if node_or_tags.size > 1

          super(node_or_tags.first)
        else
          super
        end
      end
      alias_method :<<, :add_child

      # :call-seq:
      #   xpath_doctype() → Nokogiri::CSS::XPathVisitor::DoctypeConfig
      #
      # [Returns] The document type which determines CSS-to-XPath translation.
      #
      # See XPathVisitor for more information.
      def xpath_doctype
        Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML
      end

      #
      #  :call-seq: deconstruct_keys(array_of_names) → Hash
      #
      #  Returns a hash describing the Document, to use in pattern matching.
      #
      #  Valid keys and their values:
      #  - +root+ → (Node, nil) The root node of the Document, or +nil+ if the document is empty.
      #
      #  In the future, other keys may allow accessing things like doctype and processing
      #  instructions. If you have a use case and would like this functionality, please let us know
      #  by opening an issue or a discussion on the github project.
      #
      #  *Example*
      #
      #    doc = Nokogiri::XML.parse(<<~XML)
      #      <?xml version="1.0"?>
      #      <root>
      #        <child>
      #      </root>
      #    XML
      #
      #    doc.deconstruct_keys([:root])
      #    # => {:root=>
      #    #      #(Element:0x35c {
      #    #        name = "root",
      #    #        children = [
      #    #          #(Text "\n" + "  "),
      #    #          #(Element:0x370 { name = "child", children = [ #(Text "\n")] }),
      #    #          #(Text "\n")]
      #    #        })}
      #
      #  *Example* of an empty document
      #
      #    doc = Nokogiri::XML::Document.new
      #
      #    doc.deconstruct_keys([:root])
      #    # => {:root=>nil}
      #
      #  Since v1.14.0
      #
      def deconstruct_keys(keys)
        { root: root }
      end

      private

      IMPLIED_XPATH_CONTEXTS = ["//"].freeze # :nodoc:

      def inspect_attributes
        [:name, :children]
      end
    end
  end
end
