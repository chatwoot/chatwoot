# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  module XML
    class Namespace
      include Nokogiri::XML::PP::Node
      attr_reader :document

      #
      #  :call-seq: deconstruct_keys(array_of_names) → Hash
      #
      #  Returns a hash describing the Namespace, to use in pattern matching.
      #
      #  Valid keys and their values:
      #  - +prefix+ → (String, nil) The namespace's prefix, or +nil+ if there is no prefix (e.g., default namespace).
      #  - +href+ → (String) The namespace's URI
      #
      #  *Example*
      #
      #    doc = Nokogiri::XML.parse(<<~XML)
      #      <?xml version="1.0"?>
      #      <root xmlns="http://nokogiri.org/ns/default" xmlns:noko="http://nokogiri.org/ns/noko">
      #        <child1 foo="abc" noko:bar="def"/>
      #        <noko:child2 foo="qwe" noko:bar="rty"/>
      #      </root>
      #    XML
      #
      #    doc.root.elements.first.namespace
      #    # => #(Namespace:0x35c { href = "http://nokogiri.org/ns/default" })
      #
      #    doc.root.elements.first.namespace.deconstruct_keys([:prefix, :href])
      #    # => {:prefix=>nil, :href=>"http://nokogiri.org/ns/default"}
      #
      #    doc.root.elements.last.namespace
      #    # => #(Namespace:0x370 {
      #    #      prefix = "noko",
      #    #      href = "http://nokogiri.org/ns/noko"
      #    #      })
      #
      #    doc.root.elements.last.namespace.deconstruct_keys([:prefix, :href])
      #    # => {:prefix=>"noko", :href=>"http://nokogiri.org/ns/noko"}
      #
      #  Since v1.14.0
      #
      def deconstruct_keys(keys)
        { prefix: prefix, href: href }
      end

      private

      def inspect_attributes
        [:prefix, :href]
      end
    end
  end
end
