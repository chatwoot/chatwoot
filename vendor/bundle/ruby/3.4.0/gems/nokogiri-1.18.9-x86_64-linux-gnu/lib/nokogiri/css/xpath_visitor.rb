# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  module CSS
    # When translating CSS selectors to XPath queries with Nokogiri::CSS.xpath_for, the XPathVisitor
    # class allows for changing some of the behaviors related to builtin xpath functions and quirks
    # of HTML5.
    class XPathVisitor
      WILDCARD_NAMESPACES = Nokogiri.libxml2_patches.include?("0009-allow-wildcard-namespaces.patch") # :nodoc:

      # Enum to direct XPathVisitor when to use Nokogiri builtin XPath functions.
      module BuiltinsConfig
        # Never use Nokogiri builtin functions, always generate vanilla XPath 1.0 queries. This is
        # the default when calling Nokogiri::CSS.xpath_for directly.
        NEVER = :never

        # Always use Nokogiri builtin functions whenever possible. This is probably only useful for testing.
        ALWAYS = :always

        # Only use Nokogiri builtin functions when they will be faster than vanilla XPath. This is
        # the behavior chosen when searching for CSS selectors on a Nokogiri document, fragment, or
        # node.
        OPTIMAL = :optimal

        # :nodoc: array of values for validation
        VALUES = [NEVER, ALWAYS, OPTIMAL]
      end

      # Enum to direct XPathVisitor when to tweak the XPath query to suit the nature of the document
      # being searched. Note that searches for CSS selectors from a Nokogiri document, fragment, or
      # node will choose the correct option automatically.
      module DoctypeConfig
        # The document being searched is an XML document. This is the default.
        XML = :xml

        # The document being searched is an HTML4 document.
        HTML4 = :html4

        # The document being searched is an HTML5 document.
        HTML5 = :html5

        # :nodoc: array of values for validation
        VALUES = [XML, HTML4, HTML5]
      end

      # The visitor configuration set via the +builtins:+ keyword argument to XPathVisitor.new.
      attr_reader :builtins

      # The visitor configuration set via the +doctype:+ keyword argument to XPathVisitor.new.
      attr_reader :doctype

      # The visitor configuration set via the +prefix:+ keyword argument to XPathVisitor.new.
      attr_reader :prefix

      # The visitor configuration set via the +namespaces:+ keyword argument to XPathVisitor.new.
      attr_reader :namespaces

      # :call-seq:
      #   new() → XPathVisitor
      #   new(builtins:, doctype:) → XPathVisitor
      #
      # [Parameters]
      # - +builtins:+ (BuiltinsConfig) Determine when to use Nokogiri's built-in xpath functions for performance improvements.
      # - +doctype:+ (DoctypeConfig) Make document-type-specific accommodations for CSS queries.
      #
      # [Returns] XPathVisitor
      #
      def initialize(
        builtins: BuiltinsConfig::NEVER,
        doctype: DoctypeConfig::XML,
        prefix: Nokogiri::XML::XPath::GLOBAL_SEARCH_PREFIX,
        namespaces: nil
      )
        unless BuiltinsConfig::VALUES.include?(builtins)
          raise(ArgumentError, "Invalid values #{builtins.inspect} for builtins: keyword parameter")
        end
        unless DoctypeConfig::VALUES.include?(doctype)
          raise(ArgumentError, "Invalid values #{doctype.inspect} for doctype: keyword parameter")
        end

        @builtins = builtins
        @doctype = doctype
        @prefix = prefix
        @namespaces = namespaces
      end

      # :call-seq: config() → Hash
      #
      # [Returns]
      #   a Hash representing the configuration of the XPathVisitor, suitable for use as
      #   part of the CSS cache key.
      def config
        { builtins: @builtins, doctype: @doctype, prefix: @prefix, namespaces: @namespaces }
      end

      # :stopdoc:
      def visit_function(node)
        msg = :"visit_function_#{node.value.first.gsub(/[(]/, "")}"
        return send(msg, node) if respond_to?(msg)

        case node.value.first
        when /^text\(/
          "child::text()"
        when /^self\(/
          "self::#{node.value[1]}"
        when /^eq\(/
          "position()=#{node.value[1]}"
        when /^(nth|nth-of-type)\(/
          if node.value[1].is_a?(Nokogiri::CSS::Node) && (node.value[1].type == :NTH)
            nth(node.value[1])
          else
            "position()=#{node.value[1]}"
          end
        when /^nth-child\(/
          if node.value[1].is_a?(Nokogiri::CSS::Node) && (node.value[1].type == :NTH)
            nth(node.value[1], child: true)
          else
            "count(preceding-sibling::*)=#{node.value[1].to_i - 1}"
          end
        when /^nth-last-of-type\(/
          if node.value[1].is_a?(Nokogiri::CSS::Node) && (node.value[1].type == :NTH)
            nth(node.value[1], last: true)
          else
            index = node.value[1].to_i - 1
            index == 0 ? "position()=last()" : "position()=last()-#{index}"
          end
        when /^nth-last-child\(/
          if node.value[1].is_a?(Nokogiri::CSS::Node) && (node.value[1].type == :NTH)
            nth(node.value[1], last: true, child: true)
          else
            "count(following-sibling::*)=#{node.value[1].to_i - 1}"
          end
        when /^(first|first-of-type)\(/
          "position()=1"
        when /^(last|last-of-type)\(/
          "position()=last()"
        when /^contains\(/
          "contains(.,#{node.value[1]})"
        when /^gt\(/
          "position()>#{node.value[1]}"
        when /^only-child\(/
          "last()=1"
        when /^comment\(/
          "comment()"
        when /^has\(/
          is_direct = node.value[1].value[0].nil? # e.g. "has(> a)", "has(~ a)", "has(+ a)"
          ".#{"//" unless is_direct}#{node.value[1].accept(self)}"
        else
          validate_xpath_function_name(node.value.first)

          # xpath function call, let's marshal those arguments
          args = ["."]
          args += node.value[1..-1].map do |n|
            n.is_a?(Nokogiri::CSS::Node) ? n.accept(self) : n
          end
          "nokogiri:#{node.value.first}#{args.join(",")})"
        end
      end

      def visit_not(node)
        child = node.value.first
        if :ELEMENT_NAME == child.type
          "not(self::#{child.accept(self)})"
        else
          "not(#{child.accept(self)})"
        end
      end

      def visit_id(node)
        node.value.first =~ /^#(.*)$/
        "@id='#{Regexp.last_match(1)}'"
      end

      def visit_attribute_condition(node)
        attribute = node.value.first.accept(self)
        return attribute if node.value.length == 1

        value = node.value.last
        value = "'#{value}'" unless /^['"]/.match?(value)

        # quoted values - see test_attribute_value_with_quotes in test/css/test_parser.rb
        if (value[0] == value[-1]) && %q{"'}.include?(value[0])
          str_value = value[1..-2]
          if str_value.include?(value[0])
            value = 'concat("' + str_value.split('"', -1).join(%q{",'"',"}) + '","")'
          end
        end

        case node.value[1]
        when :equal
          attribute + "=" + value.to_s
        when :not_equal
          attribute + "!=" + value.to_s
        when :substring_match
          "contains(#{attribute},#{value})"
        when :prefix_match
          "starts-with(#{attribute},#{value})"
        when :dash_match
          "#{attribute}=#{value} or starts-with(#{attribute},concat(#{value},'-'))"
        when :includes
          value = value[1..-2] # strip quotes
          css_class(attribute, value)
        when :suffix_match
          "substring(#{attribute},string-length(#{attribute})-string-length(#{value})+1,string-length(#{value}))=#{value}"
        else
          attribute + " #{node.value[1]} " + value.to_s
        end
      end

      def visit_pseudo_class(node)
        if node.value.first.is_a?(Nokogiri::CSS::Node) && (node.value.first.type == :FUNCTION)
          node.value.first.accept(self)
        else
          msg = :"visit_pseudo_class_#{node.value.first.gsub(/[(]/, "")}"
          return send(msg, node) if respond_to?(msg)

          case node.value.first
          when "first" then "position()=1"
          when "first-child" then "count(preceding-sibling::*)=0"
          when "last" then "position()=last()"
          when "last-child" then "count(following-sibling::*)=0"
          when "first-of-type" then "position()=1"
          when "last-of-type" then "position()=last()"
          when "only-child" then "count(preceding-sibling::*)=0 and count(following-sibling::*)=0"
          when "only-of-type" then "last()=1"
          when "empty" then "not(node())"
          when "parent" then "node()"
          when "root" then "not(parent::*)"
          else
            validate_xpath_function_name(node.value.first)
            "nokogiri:#{node.value.first}(.)"
          end
        end
      end

      def visit_class_condition(node)
        css_class("@class", node.value.first)
      end

      def visit_combinator(node)
        if is_of_type_pseudo_class?(node.value.last)
          "#{node.value.first&.accept(self)}][#{node.value.last.accept(self)}"
        else
          "#{node.value.first&.accept(self)} and #{node.value.last.accept(self)}"
        end
      end

      {
        "direct_adjacent_selector" => "/following-sibling::*[1]/self::",
        "following_selector" => "/following-sibling::",
        "descendant_selector" => "//",
        "child_selector" => "/",
      }.each do |k, v|
        class_eval <<~RUBY, __FILE__, __LINE__ + 1
          def visit_#{k} node
            "\#{node.value.first.accept(self) if node.value.first}#{v}\#{node.value.last.accept(self)}"
          end
        RUBY
      end

      def visit_conditional_selector(node)
        node.value.first.accept(self) + "[" +
          node.value.last.accept(self) + "]"
      end

      def visit_element_name(node)
        if @doctype == DoctypeConfig::HTML5 && html5_element_name_needs_namespace_handling(node)
          # HTML5 has namespaces that should be ignored in CSS queries
          # https://github.com/sparklemotion/nokogiri/issues/2376
          if @builtins == BuiltinsConfig::ALWAYS || (@builtins == BuiltinsConfig::OPTIMAL && Nokogiri.uses_libxml?)
            if WILDCARD_NAMESPACES
              "*:#{node.value.first}"
            else
              "*[nokogiri-builtin:local-name-is('#{node.value.first}')]"
            end
          else
            "*[local-name()='#{node.value.first}']"
          end
        elsif node.value.length == 2 # has a namespace prefix
          if node.value.first.nil? # namespace prefix is empty
            node.value.last
          else
            node.value.join(":")
          end
        elsif node.value.first != "*" && @namespaces&.key?("xmlns")
          # apply the default namespace (if one is present) to a non-wildcard selector
          "xmlns:#{node.value.first}"
        else
          node.value.first
        end
      end

      def visit_attrib_name(node)
        "@#{node.value.first}"
      end

      def accept(node)
        node.accept(self)
      end

      private

      def validate_xpath_function_name(name)
        if name.start_with?("-")
          raise Nokogiri::CSS::SyntaxError, "Invalid XPath function name '#{name}'"
        end
      end

      def html5_element_name_needs_namespace_handling(node)
        # if there is already a namespace (i.e., it is a prefixed QName), use it as normal
        node.value.length == 1 &&
          # if this is the wildcard selector "*", use it as normal
          node.value.first != "*"
      end

      def nth(node, options = {})
        unless node.value.size == 4
          raise(ArgumentError, "expected an+b node to contain 4 tokens, but is #{node.value.inspect}")
        end

        a, b = read_a_and_positive_b(node.value)
        position = if options[:child]
          options[:last] ? "(count(following-sibling::*)+1)" : "(count(preceding-sibling::*)+1)"
        else
          options[:last] ? "(last()-position()+1)" : "position()"
        end

        if b.zero?
          "(#{position} mod #{a})=0"
        else
          compare = a < 0 ? "<=" : ">="
          if a.abs == 1
            "#{position}#{compare}#{b}"
          else
            "(#{position}#{compare}#{b}) and (((#{position}-#{b}) mod #{a.abs})=0)"
          end
        end
      end

      def read_a_and_positive_b(values)
        op = values[2].strip
        if op == "+"
          a = values[0].to_i
          b = values[3].to_i
        elsif op == "-"
          a = values[0].to_i
          b = a - (values[3].to_i % a)
        else
          raise ArgumentError, "expected an+b node to have either + or - as the operator, but is #{op.inspect}"
        end
        [a, b]
      end

      def is_of_type_pseudo_class?(node) # rubocop:disable Naming/PredicateName
        if node.type == :PSEUDO_CLASS
          if node.value[0].is_a?(Nokogiri::CSS::Node) && (node.value[0].type == :FUNCTION)
            node.value[0].value[0]
          else
            node.value[0]
          end =~ /(nth|first|last|only)-of-type(\()?/
        end
      end

      def css_class(hay, needle)
        if @builtins == BuiltinsConfig::ALWAYS || (@builtins == BuiltinsConfig::OPTIMAL && Nokogiri.uses_libxml?)
          # use the builtin implementation
          "nokogiri-builtin:css-class(#{hay},'#{needle}')"
        else
          # use only ordinary xpath functions
          "contains(concat(' ',normalize-space(#{hay}),' '),' #{needle} ')"
        end
      end
    end
  end
end
