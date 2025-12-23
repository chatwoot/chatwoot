# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  class << self
    # Convenience method for Nokogiri::XSLT.parse
    def XSLT(...)
      XSLT.parse(...)
    end
  end

  ###
  # See Nokogiri::XSLT::Stylesheet for creating and manipulating
  # Stylesheet object.
  module XSLT
    class << self
      # :call-seq:
      #   parse(xsl) → Nokogiri::XSLT::Stylesheet
      #   parse(xsl, modules) → Nokogiri::XSLT::Stylesheet
      #
      # Parse the stylesheet in +xsl+, registering optional +modules+ as custom class handlers.
      #
      # [Parameters]
      # - +xsl+ (String) XSL content to be parsed into a stylesheet
      # - +modules+ (Hash<String ⇒ Class>) A hash of URI-to-handler relations for linking a
      #   namespace to a custom function handler.
      #
      # ⚠ The XSLT handler classes are registered *globally*.
      #
      # Also see Nokogiri::XSLT.register
      #
      # *Example*
      #
      #   xml = Nokogiri.XML(<<~XML)
      #     <nodes>
      #       <node>Foo</node>
      #       <node>Bar</node>
      #     </nodes>
      #   XML
      #
      #   handler = Class.new do
      #     def reverse(node)
      #       node.text.reverse
      #     end
      #   end
      #
      #   xsl = <<~XSL
      #     <xsl:stylesheet version="1.0"
      #       xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      #       xmlns:myfuncs="http://nokogiri.org/xslt/myfuncs"
      #       extension-element-prefixes="myfuncs">
      #       <xsl:template match="/">
      #         <reversed>
      #           <xsl:for-each select="nodes/node">
      #             <reverse><xsl:copy-of select="myfuncs:reverse(.)"/></reverse>
      #           </xsl:for-each>
      #         </reversed>
      #       </xsl:template>
      #     </xsl:stylesheet>
      #   XSL
      #
      #   xsl = Nokogiri.XSLT(xsl, "http://nokogiri.org/xslt/myfuncs" => handler)
      #   xsl.transform(xml).to_xml
      #   # => "<?xml version=\"1.0\"?>\n" +
      #   #    "<reversed>\n" +
      #   #    "  <reverse>ooF</reverse>\n" +
      #   #    "  <reverse>raB</reverse>\n" +
      #   #    "</reversed>\n"
      #
      def parse(string, modules = {})
        modules.each do |url, klass|
          XSLT.register(url, klass)
        end

        doc = XML::Document.parse(string, nil, nil, XML::ParseOptions::DEFAULT_XSLT)
        if Nokogiri.jruby?
          Stylesheet.parse_stylesheet_doc(doc, string)
        else
          Stylesheet.parse_stylesheet_doc(doc)
        end
      end

      # :call-seq:
      #   quote_params(params) → Array
      #
      # Quote parameters in +params+ for stylesheet safety.
      # See Nokogiri::XSLT::Stylesheet.transform for example usage.
      #
      # [Parameters]
      # - +params+ (Hash, Array) XSLT parameters (key->value, or tuples of [key, value])
      #
      # [Returns] Array of string parameters, with quotes correctly escaped for use with XSLT::Stylesheet.transform
      #
      def quote_params(params)
        params.flatten.each_slice(2).with_object([]) do |kv, quoted_params|
          key, value = kv.map(&:to_s)
          value = if value.include?("'")
            "concat('#{value.gsub("'", %q{', "'", '})}')"
          else
            "'#{value}'"
          end
          quoted_params << key
          quoted_params << value
        end
      end

      #  call-seq:
      #    register(uri, custom_handler_class)
      #
      #  Register a class that implements custom XSLT transformation functions.
      #
      #  ⚠ The XSLT handler classes are registered *globally*.
      #
      #  [Parameters}
      #  - +uri+ (String) The namespace for the custom handlers
      #  - +custom_handler_class+ (Class) A class with ruby methods that can be called during
      #    transformation
      #
      #  See Nokogiri::XSLT.parse for usage.
      #
      def register(uri, custom_handler_class)
        # NOTE: this is implemented in the C extension, see ext/nokogiri/xslt_stylesheet.c
        raise NotImplementedError, "Nokogiri::XSLT.register is not implemented on JRuby"
      end if Nokogiri.jruby?
    end
  end
end

require_relative "xslt/stylesheet"
