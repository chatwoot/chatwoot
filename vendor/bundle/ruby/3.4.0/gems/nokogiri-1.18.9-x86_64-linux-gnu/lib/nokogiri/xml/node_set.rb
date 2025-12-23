# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  module XML
    ####
    # A NodeSet is an Enumerable that contains a list of Nokogiri::XML::Node objects.
    #
    # Typically a NodeSet is returned as a result of searching a Document via
    # Nokogiri::XML::Searchable#css or Nokogiri::XML::Searchable#xpath.
    #
    # Note that the `#dup` and `#clone` methods perform shallow copies; these methods do not copy
    # the Nodes contained in the NodeSet (similar to how Array and other Enumerable classes work).
    class NodeSet
      include Nokogiri::XML::Searchable
      include Enumerable

      # The Document this NodeSet is associated with
      attr_accessor :document

      # Create a NodeSet with +document+ defaulting to +list+
      def initialize(document, list = [])
        @document = document
        document.decorate(self)
        list.each { |x| self << x }
        yield self if block_given?
      end

      ###
      # Get the first element of the NodeSet.
      def first(n = nil)
        return self[0] unless n

        list = []
        [n, length].min.times { |i| list << self[i] }
        list
      end

      ###
      # Get the last element of the NodeSet.
      def last
        self[-1]
      end

      ###
      # Is this NodeSet empty?
      def empty?
        length == 0
      end

      ###
      # Returns the index of the first node in self that is == to +node+ or meets the given block. Returns nil if no match is found.
      def index(node = nil)
        if node
          warn("given block not used") if block_given?
          each_with_index { |member, j| return j if member == node }
        elsif block_given?
          each_with_index { |member, j| return j if yield(member) }
        end
        nil
      end

      ###
      # Insert +datum+ before the first Node in this NodeSet
      def before(datum)
        first.before(datum)
      end

      ###
      # Insert +datum+ after the last Node in this NodeSet
      def after(datum)
        last.after(datum)
      end

      alias_method :<<, :push
      alias_method :remove, :unlink

      ###
      # call-seq: css *rules, [namespace-bindings, custom-pseudo-class]
      #
      # Search this node set for CSS +rules+. +rules+ must be one or more CSS
      # selectors. For example:
      #
      # For more information see Nokogiri::XML::Searchable#css
      def css(*args)
        rules, handler, ns, _ = extract_params(args)
        paths = css_rules_to_xpath(rules, ns)

        inject(NodeSet.new(document)) do |set, node|
          set + xpath_internal(node, paths, handler, ns, nil)
        end
      end

      ###
      # call-seq: xpath *paths, [namespace-bindings, variable-bindings, custom-handler-class]
      #
      # Search this node set for XPath +paths+. +paths+ must be one or more XPath
      # queries.
      #
      # For more information see Nokogiri::XML::Searchable#xpath
      def xpath(*args)
        paths, handler, ns, binds = extract_params(args)

        inject(NodeSet.new(document)) do |set, node|
          set + xpath_internal(node, paths, handler, ns, binds)
        end
      end

      ###
      # call-seq: search *paths, [namespace-bindings, xpath-variable-bindings, custom-handler-class]
      #
      # Search this object for +paths+, and return only the first
      # result. +paths+ must be one or more XPath or CSS queries.
      #
      # See Searchable#search for more information.
      #
      # Or, if passed an integer, index into the NodeSet:
      #
      #   node_set.at(3) # same as node_set[3]
      #
      def at(*args)
        if args.length == 1 && args.first.is_a?(Numeric)
          return self[args.first]
        end

        super
      end
      alias_method :%, :at

      ###
      # Filter this list for nodes that match +expr+
      def filter(expr)
        find_all { |node| node.matches?(expr) }
      end

      ###
      # Add the class attribute +name+ to all Node objects in the
      # NodeSet.
      #
      # See Nokogiri::XML::Node#add_class for more information.
      def add_class(name)
        each do |el|
          el.add_class(name)
        end
        self
      end

      ###
      # Append the class attribute +name+ to all Node objects in the
      # NodeSet.
      #
      # See Nokogiri::XML::Node#append_class for more information.
      def append_class(name)
        each do |el|
          el.append_class(name)
        end
        self
      end

      ###
      # Remove the class attribute +name+ from all Node objects in the
      # NodeSet.
      #
      # See Nokogiri::XML::Node#remove_class for more information.
      def remove_class(name = nil)
        each do |el|
          el.remove_class(name)
        end
        self
      end

      ###
      # Set attributes on each Node in the NodeSet, or get an
      # attribute from the first Node in the NodeSet.
      #
      # To get an attribute from the first Node in a NodeSet:
      #
      #   node_set.attr("href") # => "https://www.nokogiri.org"
      #
      # Note that an empty NodeSet will return nil when +#attr+ is called as a getter.
      #
      # To set an attribute on each node, +key+ can either be an
      # attribute name, or a Hash of attribute names and values. When
      # called as a setter, +#attr+ returns the NodeSet.
      #
      # If +key+ is an attribute name, then either +value+ or +block+
      # must be passed.
      #
      # If +key+ is a Hash then attributes will be set for each
      # key/value pair:
      #
      #   node_set.attr("href" => "https://www.nokogiri.org", "class" => "member")
      #
      # If +value+ is passed, it will be used as the attribute value
      # for all nodes:
      #
      #   node_set.attr("href", "https://www.nokogiri.org")
      #
      # If +block+ is passed, it will be called on each Node object in
      # the NodeSet and the return value used as the attribute value
      # for that node:
      #
      #   node_set.attr("class") { |node| node.name }
      #
      def attr(key, value = nil, &block)
        unless key.is_a?(Hash) || (key && (value || block))
          return first&.attribute(key)
        end

        hash = key.is_a?(Hash) ? key : { key => value }

        hash.each do |k, v|
          each do |node|
            node[k] = v || yield(node)
          end
        end

        self
      end
      alias_method :set, :attr
      alias_method :attribute, :attr

      ###
      # Remove the attributed named +name+ from all Node objects in the NodeSet
      def remove_attr(name)
        each { |el| el.delete(name) }
        self
      end
      alias_method :remove_attribute, :remove_attr

      ###
      # Iterate over each node, yielding  to +block+
      def each
        return to_enum unless block_given?

        0.upto(length - 1) do |x|
          yield self[x]
        end
        self
      end

      ###
      # Get the inner text of all contained Node objects
      #
      # Note: This joins the text of all Node objects in the NodeSet:
      #
      #    doc = Nokogiri::XML('<xml><a><d>foo</d><d>bar</d></a></xml>')
      #    doc.css('d').text # => "foobar"
      #
      # Instead, if you want to return the text of all nodes in the NodeSet:
      #
      #    doc.css('d').map(&:text) # => ["foo", "bar"]
      #
      # See Nokogiri::XML::Node#content for more information.
      def inner_text
        collect(&:inner_text).join("")
      end
      alias_method :text, :inner_text

      ###
      # Get the inner html of all contained Node objects
      def inner_html(*args)
        collect { |j| j.inner_html(*args) }.join("")
      end

      # :call-seq:
      #   wrap(markup) -> self
      #   wrap(node) -> self
      #
      # Wrap each member of this NodeSet with the node parsed from +markup+ or a dup of the +node+.
      #
      # [Parameters]
      # - *markup* (String)
      #   Markup that is parsed, once per member of the NodeSet, and used as the wrapper. Each
      #   node's parent, if it exists, is used as the context node for parsing; otherwise the
      #   associated document is used. If the parsed fragment has multiple roots, the first root
      #   node is used as the wrapper.
      # - *node* (Nokogiri::XML::Node)
      #   An element that is `#dup`ed and used as the wrapper.
      #
      # [Returns] +self+, to support chaining.
      #
      # ⚠ Note that if a +String+ is passed, the markup will be parsed <b>once per node</b> in the
      # NodeSet. You can avoid this overhead in cases where you know exactly the wrapper you wish to
      # use by passing a +Node+ instead.
      #
      # Also see Node#wrap
      #
      # *Example* with a +String+ argument:
      #
      #   doc = Nokogiri::HTML5(<<~HTML)
      #     <html><body>
      #       <a>a</a>
      #       <a>b</a>
      #       <a>c</a>
      #       <a>d</a>
      #     </body></html>
      #   HTML
      #   doc.css("a").wrap("<div></div>")
      #   doc.to_html
      #   # => <html><head></head><body>
      #   #      <div><a>a</a></div>
      #   #      <div><a>b</a></div>
      #   #      <div><a>c</a></div>
      #   #      <div><a>d</a></div>
      #   #    </body></html>
      #
      # *Example* with a +Node+ argument
      #
      # 💡 Note that this is faster than the equivalent call passing a +String+ because it avoids
      # having to reparse the wrapper markup for each node.
      #
      #   doc = Nokogiri::HTML5(<<~HTML)
      #     <html><body>
      #       <a>a</a>
      #       <a>b</a>
      #       <a>c</a>
      #       <a>d</a>
      #     </body></html>
      #   HTML
      #   doc.css("a").wrap(doc.create_element("div"))
      #   doc.to_html
      #   # => <html><head></head><body>
      #   #      <div><a>a</a></div>
      #   #      <div><a>b</a></div>
      #   #      <div><a>c</a></div>
      #   #      <div><a>d</a></div>
      #   #    </body></html>
      #
      def wrap(node_or_tags)
        map { |node| node.wrap(node_or_tags) }
        self
      end

      ###
      # Convert this NodeSet to a string.
      def to_s
        map(&:to_s).join
      end

      ###
      # Convert this NodeSet to HTML
      def to_html(*args)
        if Nokogiri.jruby?
          options = args.first.is_a?(Hash) ? args.shift : {}
          options[:save_with] ||= Node::SaveOptions::DEFAULT_HTML
          args.insert(0, options)
        end
        if empty?
          encoding = (args.first.is_a?(Hash) ? args.first[:encoding] : nil)
          encoding ||= document.encoding
          encoding.nil? ? "" : "".encode(encoding)
        else
          map { |x| x.to_html(*args) }.join
        end
      end

      ###
      # Convert this NodeSet to XHTML
      def to_xhtml(*args)
        map { |x| x.to_xhtml(*args) }.join
      end

      ###
      # Convert this NodeSet to XML
      def to_xml(*args)
        map { |x| x.to_xml(*args) }.join
      end

      alias_method :size, :length
      alias_method :to_ary, :to_a

      ###
      # Removes the last element from set and returns it, or +nil+ if
      # the set is empty
      def pop
        return if length == 0

        delete(last)
      end

      ###
      # Returns the first element of the NodeSet and removes it.  Returns
      # +nil+ if the set is empty.
      def shift
        return if length == 0

        delete(first)
      end

      ###
      # Equality -- Two NodeSets are equal if the contain the same number
      # of elements and if each element is equal to the corresponding
      # element in the other NodeSet
      def ==(other)
        return false unless other.is_a?(Nokogiri::XML::NodeSet)
        return false unless length == other.length

        each_with_index do |node, i|
          return false unless node == other[i]
        end
        true
      end

      ###
      # Returns a new NodeSet containing all the children of all the nodes in
      # the NodeSet
      def children
        node_set = NodeSet.new(document)
        each do |node|
          node.children.each { |n| node_set.push(n) }
        end
        node_set
      end

      ###
      # Returns a new NodeSet containing all the nodes in the NodeSet
      # in reverse order
      def reverse
        node_set = NodeSet.new(document)
        (length - 1).downto(0) do |x|
          node_set.push(self[x])
        end
        node_set
      end

      ###
      # Return a nicely formatted string representation
      def inspect
        "[#{map(&:inspect).join(", ")}]"
      end

      alias_method :+, :|

      #
      #  :call-seq: deconstruct() → Array
      #
      #  Returns the members of this NodeSet as an array, to use in pattern matching.
      #
      #  Since v1.14.0
      #
      def deconstruct
        to_a
      end

      IMPLIED_XPATH_CONTEXTS = [".//", "self::"].freeze # :nodoc:
    end
  end
end
