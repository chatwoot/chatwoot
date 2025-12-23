# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  module XML
    #
    #  The Searchable module declares the interface used for searching your DOM.
    #
    #  It implements the public methods #search, #css, and #xpath,
    #  as well as allowing specific implementations to specialize some
    #  of the important behaviors.
    #
    module Searchable
      # Regular expression used by Searchable#search to determine if a query
      # string is CSS or XPath
      LOOKS_LIKE_XPATH = %r{^(\./|/|\.\.|\.$)}

      # :section: Searching via XPath or CSS Queries

      ###
      # call-seq:
      #   search(*paths, [namespace-bindings, xpath-variable-bindings, custom-handler-class])
      #
      # Search this object for +paths+. +paths+ must be one or more XPath or CSS queries:
      #
      #   node.search("div.employee", ".//title")
      #
      # A hash of namespace bindings may be appended:
      #
      #   node.search('.//bike:tire', {'bike' => 'http://schwinn.com/'})
      #   node.search('bike|tire', {'bike' => 'http://schwinn.com/'})
      #
      # For XPath queries, a hash of variable bindings may also be appended to the namespace
      # bindings. For example:
      #
      #   node.search('.//address[@domestic=$value]', nil, {:value => 'Yes'})
      #
      # 💡 Custom XPath functions and CSS pseudo-selectors may also be defined. To define custom
      # functions create a class and implement the function you want to define, which will be in the
      # `nokogiri` namespace in XPath queries.
      #
      # The first argument to the method will be the current matching NodeSet. Any other arguments
      # are ones that you pass in. Note that this class may appear anywhere in the argument
      # list. For example:
      #
      #   handler = Class.new {
      #     def regex node_set, regex
      #       node_set.find_all { |node| node['some_attribute'] =~ /#{regex}/ }
      #     end
      #   }.new
      #   node.search('.//title[nokogiri:regex(., "\w+")]', 'div.employee:regex("[0-9]+")', handler)
      #
      # See Searchable#xpath and Searchable#css for further usage help.
      def search(*args)
        paths, handler, ns, binds = extract_params(args)

        xpaths = paths.map(&:to_s).map do |path|
          LOOKS_LIKE_XPATH.match?(path) ? path : xpath_query_from_css_rule(path, ns)
        end.flatten.uniq

        xpath(*(xpaths + [ns, handler, binds].compact))
      end

      alias_method :/, :search

      ###
      # call-seq:
      #   at(*paths, [namespace-bindings, xpath-variable-bindings, custom-handler-class])
      #
      # Search this object for +paths+, and return only the first
      # result. +paths+ must be one or more XPath or CSS queries.
      #
      # See Searchable#search for more information.
      def at(*args)
        search(*args).first
      end

      alias_method :%, :at

      ###
      # call-seq:
      #   css(*rules, [namespace-bindings, custom-pseudo-class])
      #
      # Search this object for CSS +rules+. +rules+ must be one or more CSS
      # selectors. For example:
      #
      #   node.css('title')
      #   node.css('body h1.bold')
      #   node.css('div + p.green', 'div#one')
      #
      # A hash of namespace bindings may be appended. For example:
      #
      #   node.css('bike|tire', {'bike' => 'http://schwinn.com/'})
      #
      # 💡 Custom CSS pseudo classes may also be defined which are mapped to a custom XPath
      # function.  To define custom pseudo classes, create a class and implement the custom pseudo
      # class you want defined. The first argument to the method will be the matching context
      # NodeSet. Any other arguments are ones that you pass in. For example:
      #
      #   handler = Class.new {
      #     def regex(node_set, regex)
      #       node_set.find_all { |node| node['some_attribute'] =~ /#{regex}/ }
      #     end
      #   }.new
      #   node.css('title:regex("\w+")', handler)
      #
      # 💡 Some XPath syntax is supported in CSS queries. For example, to query for an attribute:
      #
      #   node.css('img > @href') # returns all +href+ attributes on an +img+ element
      #   node.css('img / @href') # same
      #
      #   # ⚠ this returns +class+ attributes from all +div+ elements AND THEIR CHILDREN!
      #   node.css('div @class')
      #
      #   node.css
      #
      # 💡 Array-like syntax is supported in CSS queries as an alternative to using +:nth-child()+.
      #
      # ⚠ NOTE that indices are 1-based like +:nth-child+ and not 0-based like Ruby Arrays. For
      # example:
      #
      #   # equivalent to 'li:nth-child(2)'
      #   node.css('li[2]') # retrieve the second li element in a list
      #
      # ⚠ NOTE that the CSS query string is case-sensitive with regards to your document type. HTML
      # tags will match only lowercase CSS queries, so if you search for "H1" in an HTML document,
      # you'll never find anything. However, "H1" might be found in an XML document, where tags
      # names are case-sensitive (e.g., "H1" is distinct from "h1").
      def css(*args)
        rules, handler, ns, _ = extract_params(args)

        css_internal(self, rules, handler, ns)
      end

      ##
      # call-seq:
      #   at_css(*rules, [namespace-bindings, custom-pseudo-class])
      #
      # Search this object for CSS +rules+, and return only the first
      # match. +rules+ must be one or more CSS selectors.
      #
      # See Searchable#css for more information.
      def at_css(*args)
        css(*args).first
      end

      ###
      # call-seq:
      #   xpath(*paths, [namespace-bindings, variable-bindings, custom-handler-class])
      #
      # Search this node for XPath +paths+. +paths+ must be one or more XPath
      # queries.
      #
      #   node.xpath('.//title')
      #
      # A hash of namespace bindings may be appended. For example:
      #
      #   node.xpath('.//foo:name', {'foo' => 'http://example.org/'})
      #   node.xpath('.//xmlns:name', node.root.namespaces)
      #
      # A hash of variable bindings may also be appended to the namespace bindings. For example:
      #
      #   node.xpath('.//address[@domestic=$value]', nil, {:value => 'Yes'})
      #
      # 💡 Custom XPath functions may also be defined. To define custom functions create a class and
      # implement the function you want to define, which will be in the `nokogiri` namespace.
      #
      # The first argument to the method will be the current matching NodeSet. Any other arguments
      # are ones that you pass in. Note that this class may appear anywhere in the argument
      # list. For example:
      #
      #   handler = Class.new {
      #     def regex(node_set, regex)
      #       node_set.find_all { |node| node['some_attribute'] =~ /#{regex}/ }
      #     end
      #   }.new
      #   node.xpath('.//title[nokogiri:regex(., "\w+")]', handler)
      #
      def xpath(*args)
        paths, handler, ns, binds = extract_params(args)

        xpath_internal(self, paths, handler, ns, binds)
      end

      ##
      # call-seq:
      #   at_xpath(*paths, [namespace-bindings, variable-bindings, custom-handler-class])
      #
      # Search this node for XPath +paths+, and return only the first
      # match. +paths+ must be one or more XPath queries.
      #
      # See Searchable#xpath for more information.
      def at_xpath(*args)
        xpath(*args).first
      end

      # :call-seq:
      #   >(selector) → NodeSet
      #
      # Search this node's immediate children using CSS selector +selector+
      def >(selector) # rubocop:disable Naming/BinaryOperatorParameterName
        ns = document.root&.namespaces || {}
        xpath(CSS.xpath_for(selector, prefix: "./", ns: ns).first)
      end

      # :section:

      private

      def extract_params(params) # :nodoc:
        handler = params.find do |param|
          ![Hash, String, Symbol].include?(param.class)
        end
        params -= [handler] if handler

        hashes = []
        while Hash === params.last || params.last.nil?
          hashes << params.pop
          break if params.empty?
        end
        ns, binds = hashes.reverse

        ns ||= document.root&.namespaces || {}

        [params, handler, ns, binds]
      end

      def css_internal(node, rules, handler, ns)
        xpath_internal(node, css_rules_to_xpath(rules, ns), handler, ns, nil)
      end

      def css_rules_to_xpath(rules, ns)
        rules.map { |rule| xpath_query_from_css_rule(rule, ns) }
      end

      def xpath_query_from_css_rule(rule, ns)
        self.class::IMPLIED_XPATH_CONTEXTS.map do |implied_xpath_context|
          visitor = Nokogiri::CSS::XPathVisitor.new(
            builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::OPTIMAL,
            doctype: document.xpath_doctype,
            prefix: implied_xpath_context,
            namespaces: ns,
          )
          CSS.xpath_for(rule.to_s, visitor: visitor)
        end.join(" | ")
      end

      def xpath_internal(node, paths, handler, ns, binds)
        document = node.document
        return NodeSet.new(document) unless document

        if paths.length == 1
          return xpath_impl(node, paths.first, handler, ns, binds)
        end

        NodeSet.new(document) do |combined|
          paths.each do |path|
            xpath_impl(node, path, handler, ns, binds).each { |set| combined << set }
          end
        end
      end

      def xpath_impl(node, path, handler, ns, binds)
        context = XPathContext.new(node)
        context.register_namespaces(ns)
        context.register_variables(binds)

        path = path.gsub("xmlns:", " :") unless Nokogiri.uses_libxml?

        context.evaluate(path, handler)
      end
    end
  end
end
