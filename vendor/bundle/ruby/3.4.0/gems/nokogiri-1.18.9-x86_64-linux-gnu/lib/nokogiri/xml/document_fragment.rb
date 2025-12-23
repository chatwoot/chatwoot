# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  module XML
    # DocumentFragment represents a fragment of an \XML document. It provides the same functionality
    # exposed by XML::Node and can be used to contain one or more \XML subtrees.
    class DocumentFragment < Nokogiri::XML::Node
      # The options used to parse the document fragment. Returns the value of any options that were
      # passed into the constructor as a parameter or set in a config block, else the default
      # options for the specific subclass.
      attr_reader :parse_options

      class << self
        # :call-seq:
        #   parse(input) { |options| ... } → XML::DocumentFragment
        #   parse(input, options:) → XML::DocumentFragment
        #
        # Parse \XML fragment input from a String, and return a new XML::DocumentFragment. This
        # method creates a new, empty XML::Document to contain the fragment.
        #
        # [Required Parameters]
        # - +input+ (String) The content to be parsed.
        #
        # [Optional Keyword Arguments]
        # - +options+ (Nokogiri::XML::ParseOptions) Configuration object that determines some
        #   behaviors during parsing. See ParseOptions for more information. The default value is
        #   +ParseOptions::DEFAULT_XML+.
        #
        # [Yields]
        #   If a block is given, a Nokogiri::XML::ParseOptions object is yielded to the block which
        #   can be configured before parsing. See Nokogiri::XML::ParseOptions for more information.
        #
        # [Returns] Nokogiri::XML::DocumentFragment
        def parse(tags, options_ = ParseOptions::DEFAULT_XML, options: options_, &block)
          new(XML::Document.new, tags, options: options, &block)
        end

        # Wrapper method to separate the concerns of:
        # - the native object allocator's parameter (it only requires `document`)
        # - the initializer's parameters
        def new(document, ...) # :nodoc:
          instance = native_new(document)
          instance.send(:initialize, document, ...)
          instance
        end
      end

      # :call-seq:
      #   new(document, input=nil) { |options| ... } → DocumentFragment
      #   new(document, input=nil, context:, options:) → DocumentFragment
      #
      # Parse \XML fragment input from a String, and return a new DocumentFragment that is
      # associated with the given +document+.
      #
      # 💡 It's recommended to use either XML::DocumentFragment.parse or Node#parse rather than call
      # this method directly.
      #
      # [Required Parameters]
      # - +document+ (XML::Document) The parent document to associate the returned fragment with.
      #
      # [Optional Parameters]
      # - +input+ (String) The content to be parsed.
      #
      # [Optional Keyword Arguments]
      # - +context:+ (Nokogiri::XML::Node) The <b>context node</b> for the subtree created. See
      #   below for more information.
      #
      # - +options:+ (Nokogiri::XML::ParseOptions) Configuration object that determines some
      #   behaviors during parsing. See ParseOptions for more information. The default value is
      #   +ParseOptions::DEFAULT_XML+.
      #
      # [Yields]
      #   If a block is given, a Nokogiri::XML::ParseOptions object is yielded to the block which
      #   can be configured before parsing. See ParseOptions for more information.
      #
      # [Returns] XML::DocumentFragment
      #
      # === Context \Node
      #
      # If a context node is specified using +context:+, then the fragment will be created by
      # calling Node#parse on that node, so the parser will behave as if that Node is the parent of
      # the fragment subtree, and will resolve namespaces relative to that node.
      #
      def initialize(
        document, tags = nil,
        context_ = nil, options_ = ParseOptions::DEFAULT_XML,
        context: context_, options: options_
      ) # rubocop:disable Lint/MissingSuper
        return self unless tags

        options = Nokogiri::XML::ParseOptions.new(options) if Integer === options
        @parse_options = options
        yield options if block_given?

        children = if context
          # Fix for issue#490
          if Nokogiri.jruby?
            # fix for issue #770
            context.parse("<root #{namespace_declarations(context)}>#{tags}</root>", options).children
          else
            context.parse(tags, options)
          end
        else
          wrapper_doc = XML::Document.parse("<root>#{tags}</root>", nil, nil, options)
          self.errors = wrapper_doc.errors
          wrapper_doc.xpath("/root/node()")
        end
        children.each { |child| child.parent = self }
      end

      if Nokogiri.uses_libxml?
        def dup
          new_document = document.dup
          new_fragment = self.class.new(new_document)
          children.each do |child|
            child.dup(1, new_document).parent = new_fragment
          end
          new_fragment
        end
      end

      ###
      # return the name for DocumentFragment
      def name
        "#document-fragment"
      end

      ###
      # Convert this DocumentFragment to a string
      def to_s
        children.to_s
      end

      ###
      # Convert this DocumentFragment to html
      # See Nokogiri::XML::NodeSet#to_html
      def to_html(*args)
        if Nokogiri.jruby?
          options = args.first.is_a?(Hash) ? args.shift : {}
          options[:save_with] ||= Node::SaveOptions::DEFAULT_HTML
          args.insert(0, options)
        end
        children.to_html(*args)
      end

      ###
      # Convert this DocumentFragment to xhtml
      # See Nokogiri::XML::NodeSet#to_xhtml
      def to_xhtml(*args)
        if Nokogiri.jruby?
          options = args.first.is_a?(Hash) ? args.shift : {}
          options[:save_with] ||= Node::SaveOptions::DEFAULT_XHTML
          args.insert(0, options)
        end
        children.to_xhtml(*args)
      end

      ###
      # Convert this DocumentFragment to xml
      # See Nokogiri::XML::NodeSet#to_xml
      def to_xml(*args)
        children.to_xml(*args)
      end

      ###
      # call-seq: css *rules, [namespace-bindings, custom-pseudo-class]
      #
      # Search this fragment for CSS +rules+. +rules+ must be one or more CSS
      # selectors. For example:
      #
      # For more information see Nokogiri::XML::Searchable#css
      def css(*args)
        if children.any?
          children.css(*args) # 'children' is a smell here
        else
          NodeSet.new(document)
        end
      end

      #
      #  NOTE that we don't delegate #xpath to children ... another smell.
      #  def xpath ; end
      #

      ###
      # call-seq: search *paths, [namespace-bindings, xpath-variable-bindings, custom-handler-class]
      #
      # Search this fragment for +paths+. +paths+ must be one or more XPath or CSS queries.
      #
      # For more information see Nokogiri::XML::Searchable#search
      def search(*rules)
        rules, handler, ns, binds = extract_params(rules)

        rules.inject(NodeSet.new(document)) do |set, rule|
          set + if Searchable::LOOKS_LIKE_XPATH.match?(rule)
            xpath(*[rule, ns, handler, binds].compact)
          else
            children.css(*[rule, ns, handler].compact) # 'children' is a smell here
          end
        end
      end

      alias_method :serialize, :to_s

      # A list of Nokogiri::XML::SyntaxError found when parsing a document
      def errors
        document.errors
      end

      def errors=(things) # :nodoc:
        document.errors = things
      end

      def fragment(data)
        document.fragment(data)
      end

      #
      #  :call-seq: deconstruct() → Array
      #
      #  Returns the root nodes of this document fragment as an array, to use in pattern matching.
      #
      #  💡 Note that text nodes are returned as well as elements. If you wish to operate only on
      #  root elements, you should deconstruct the array returned by
      #  <tt>DocumentFragment#elements</tt>.
      #
      #  *Example*
      #
      #    frag = Nokogiri::HTML5.fragment(<<~HTML)
      #      <div>Start</div>
      #      This is a <a href="#jump">shortcut</a> for you.
      #      <div>End</div>
      #    HTML
      #
      #    frag.deconstruct
      #    # => [#(Element:0x35c { name = "div", children = [ #(Text "Start")] }),
      #    #     #(Text "\n" + "This is a "),
      #    #     #(Element:0x370 {
      #    #       name = "a",
      #    #       attributes = [ #(Attr:0x384 { name = "href", value = "#jump" })],
      #    #       children = [ #(Text "shortcut")]
      #    #       }),
      #    #     #(Text " for you.\n"),
      #    #     #(Element:0x398 { name = "div", children = [ #(Text "End")] }),
      #    #     #(Text "\n")]
      #
      #  *Example* only the elements, not the text nodes.
      #
      #    frag.elements.deconstruct
      #    # => [#(Element:0x35c { name = "div", children = [ #(Text "Start")] }),
      #    #     #(Element:0x370 {
      #    #       name = "a",
      #    #       attributes = [ #(Attr:0x384 { name = "href", value = "#jump" })],
      #    #       children = [ #(Text "shortcut")]
      #    #       }),
      #    #     #(Element:0x398 { name = "div", children = [ #(Text "End")] })]
      #
      #  Since v1.14.0
      #
      def deconstruct
        children.to_a
      end

      private

      # fix for issue 770
      def namespace_declarations(ctx)
        ctx.namespace_scopes.map do |namespace|
          prefix = namespace.prefix.nil? ? "" : ":#{namespace.prefix}"
          %{xmlns#{prefix}="#{namespace.href}"}
        end.join(" ")
      end
    end
  end
end
