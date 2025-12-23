# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  module XML
    class Attr < Node
      alias_method :value, :content
      alias_method :to_s, :content
      alias_method :content=, :value=

      #
      #  :call-seq: deconstruct_keys(array_of_names) → Hash
      #
      #  Returns a hash describing the Attr, to use in pattern matching.
      #
      #  Valid keys and their values:
      #  - +name+ → (String) The name of the attribute.
      #  - +value+ → (String) The value of the attribute.
      #  - +namespace+ → (Namespace, nil) The Namespace of the attribute, or +nil+ if there is no namespace.
      #
      #  *Example*
      #
      #    doc = Nokogiri::XML.parse(<<~XML)
      #      <?xml version="1.0"?>
      #      <root xmlns="http://nokogiri.org/ns/default" xmlns:noko="http://nokogiri.org/ns/noko">
      #        <child1 foo="abc" noko:bar="def"/>
      #      </root>
      #    XML
      #
      #    attributes = doc.root.elements.first.attribute_nodes
      #    # => [#(Attr:0x35c { name = "foo", value = "abc" }),
      #    #     #(Attr:0x370 {
      #    #       name = "bar",
      #    #       namespace = #(Namespace:0x384 {
      #    #         prefix = "noko",
      #    #         href = "http://nokogiri.org/ns/noko"
      #    #         }),
      #    #       value = "def"
      #    #       })]
      #
      #    attributes.first.deconstruct_keys([:name, :value, :namespace])
      #    # => {:name=>"foo", :value=>"abc", :namespace=>nil}
      #
      #    attributes.last.deconstruct_keys([:name, :value, :namespace])
      #    # => {:name=>"bar",
      #    #     :value=>"def",
      #    #     :namespace=>
      #    #      #(Namespace:0x384 {
      #    #        prefix = "noko",
      #    #        href = "http://nokogiri.org/ns/noko"
      #    #        })}
      #
      #  Since v1.14.0
      #
      def deconstruct_keys(keys)
        { name: name, value: value, namespace: namespace }
      end

      private

      def inspect_attributes
        [:name, :namespace, :value]
      end
    end
  end
end
