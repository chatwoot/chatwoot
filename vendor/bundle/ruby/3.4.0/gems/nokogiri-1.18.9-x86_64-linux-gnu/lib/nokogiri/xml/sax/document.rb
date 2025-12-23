# frozen_string_literal: true

module Nokogiri
  module XML
    module SAX
      # :markup: markdown
      #
      # The SAX::Document class is used for registering types of events you are interested in
      # handling. All of the methods on this class are available as possible events while parsing an
      # \XML document. To register for any particular event, subclass this class and implement the
      # methods you are interested in knowing about.
      #
      # To only be notified about start and end element events, write a class like this:
      #
      #     class MyHandler < Nokogiri::XML::SAX::Document
      #       def start_element name, attrs = []
      #         puts "#{name} started!"
      #       end
      #
      #       def end_element name
      #         puts "#{name} ended"
      #       end
      #     end
      #
      # You can use this event handler for any SAX-style parser included with Nokogiri.
      #
      # See also:
      #
      # - Nokogiri::XML::SAX
      # - Nokogiri::HTML4::SAX
      #
      # ### Entity Handling
      #
      # ⚠ Entity handling is complicated in a SAX parser! Please read this section carefully if
      # you're not getting the behavior you expect.
      #
      # Entities will be reported to the user via callbacks to #characters, to #reference, or
      # possibly to both. The behavior is determined by a combination of _entity type_ and the value
      # of ParserContext#replace_entities. (Recall that the default value of
      # ParserContext#replace_entities is `false`.)
      #
      # ⚠ <b>It is UNSAFE to set ParserContext#replace_entities to `true`</b> when parsing untrusted
      # documents.
      #
      # 💡 For more information on entity types, see [Wikipedia's page on
      # DTDs](https://en.wikipedia.org/wiki/Document_type_definition#Entity_declarations).
      #
      # | Entity type                          | #characters                        | #reference                          |
      # |--------------------------------------|------------------------------------|-------------------------------------|
      # | Char ref (e.g., <tt>&#146;</tt>)     | always                             | never                               |
      # | Predefined (e.g., <tt>&amp;</tt>)    | always                             | never                               |
      # | Undeclared †                         | never                              | <tt>#replace_entities == false</tt> |
      # | Internal                             | always                             | <tt>#replace_entities == false</tt> |
      # | External †                           | <tt>#replace_entities == true</tt> | <tt>#replace_entities == false</tt> |
      #
      # &nbsp;
      #
      # † In the case where the replacement text for the entity is unknown (e.g., an undeclared entity
      # or an external entity that could not be resolved because of network issues), then the
      # replacement text will not be reported. If ParserContext#replace_entities is `true`, this
      # means the #characters callback will not be invoked. If ParserContext#replace_entities is
      # `false`, then the #reference callback will be invoked, but with `nil` for the `content`
      # argument.
      #
      class Document
        ###
        # Called when an \XML declaration is parsed.
        #
        # [Parameters]
        # - +version+ (String) the version attribute
        # - +encoding+ (String, nil) the encoding of the document if present, else +nil+
        # - +standalone+ ("yes", "no", nil) the standalone attribute if present, else +nil+
        def xmldecl(version, encoding, standalone)
        end

        ###
        # Called when document starts parsing.
        def start_document
        end

        ###
        # Called when document ends parsing.
        def end_document
        end

        ###
        # Called at the beginning of an element.
        #
        # [Parameters]
        # - +name+ (String) the name of the element
        # - +attrs+ (Array<Array<String>>) an assoc list of namespace declarations and attributes, e.g.:
        #     [ ["xmlns:foo", "http://sample.net"], ["size", "large"] ]
        #
        # 💡If you're dealing with XML and need to handle namespaces, use the
        # #start_element_namespace method instead.
        #
        # Note that the element namespace and any attribute namespaces are not provided, and so any
        # namespaced elements or attributes will be returned as strings including the prefix:
        #
        #   parser.parse(<<~XML)
        #     <root xmlns:foo='http://foo.example.com/' xmlns='http://example.com/'>
        #       <foo:bar foo:quux="xxx">hello world</foo:bar>
        #     </root>
        #   XML
        #
        #   assert_pattern do
        #     parser.document.start_elements => [
        #       ["root", [["xmlns:foo", "http://foo.example.com/"], ["xmlns", "http://example.com/"]]],
        #       ["foo:bar", [["foo:quux", "xxx"]]],
        #     ]
        #   end
        #
        def start_element(name, attrs = [])
        end

        ###
        # Called at the end of an element.
        #
        # [Parameters]
        # - +name+ (String) the name of the element being closed
        #
        def end_element(name)
        end

        ###
        # Called at the beginning of an element.
        #
        # [Parameters]
        # - +name+ (String) is the name of the element
        # - +attrs+ (Array<Attribute>) is an array of structs with the following properties:
        #   - +localname+ (String) the local name of the attribute
        #   - +value+ (String) the value of the attribute
        #   - +prefix+ (String, nil) the namespace prefix of the attribute
        #   - +uri+ (String, nil) the namespace URI of the attribute
        # - +prefix+ (String, nil) is the namespace prefix for the element
        # - +uri+ (String, nil) is the associated URI for the element's namespace
        # - +ns+ (Array<Array<String, String>>) is an assoc list of namespace declarations on the element
        #
        # 💡If you're dealing with HTML or don't care about namespaces, try #start_element instead.
        #
        # [Example]
        #   it "start_elements_namespace is called with namespaced attributes" do
        #     parser.parse(<<~XML)
        #       <root xmlns:foo='http://foo.example.com/'>
        #         <foo:a foo:bar='hello' />
        #       </root>
        #     XML
        #
        #     assert_pattern do
        #       parser.document.start_elements_namespace => [
        #         [
        #           "root",
        #           [],
        #           nil, nil,
        #           [["foo", "http://foo.example.com/"]], # namespace declarations
        #         ], [
        #           "a",
        #           [Nokogiri::XML::SAX::Parser::Attribute(localname: "bar", prefix: "foo", uri: "http://foo.example.com/", value: "hello")], # prefixed attribute
        #           "foo", "http://foo.example.com/", # prefix and uri for the "a" element
        #           [],
        #         ]
        #       ]
        #     end
        #   end
        #
        def start_element_namespace(name, attrs = [], prefix = nil, uri = nil, ns = []) # rubocop:disable Metrics/ParameterLists
          # Deal with SAX v1 interface
          name = [prefix, name].compact.join(":")
          attributes = ns.map do |ns_prefix, ns_uri|
            [["xmlns", ns_prefix].compact.join(":"), ns_uri]
          end + attrs.map do |attr|
            [[attr.prefix, attr.localname].compact.join(":"), attr.value]
          end
          start_element(name, attributes)
        end

        ###
        # Called at the end of an element.
        #
        # [Parameters]
        # - +name+ (String) is the name of the element
        # - +prefix+ (String, nil) is the namespace prefix for the element
        # - +uri+ (String, nil) is the associated URI for the element's namespace
        #
        def end_element_namespace(name, prefix = nil, uri = nil)
          # Deal with SAX v1 interface
          end_element([prefix, name].compact.join(":"))
        end

        ###
        # Called when character data is parsed, and for parsed entities when
        # ParserContext#replace_entities is +true+.
        #
        # [Parameters]
        # - +string+ contains the character data or entity replacement text
        #
        # ⚠ Please see Document@Entity+Handling for important information about how entities are handled.
        #
        # ⚠ This method might be called multiple times for a contiguous string of characters.
        #
        def characters(string)
        end

        ###
        # Called when a parsed entity is referenced and not replaced.
        #
        # [Parameters]
        # - +name+ (String) is the name of the entity
        # - +content+ (String, nil) is the replacement text for the entity, if known
        #
        # ⚠ Please see Document@Entity+Handling for important information about how entities are handled.
        #
        # ⚠ An internal entity may result in a call to both #characters and #reference.
        #
        # Since v1.17.0
        #
        def reference(name, content)
        end

        ###
        # Called when comments are encountered
        # [Parameters]
        # - +string+ contains the comment data
        def comment(string)
        end

        ###
        # Called on document warnings
        # [Parameters]
        # - +string+ contains the warning
        def warning(string)
        end

        ###
        # Called on document errors
        # [Parameters]
        # - +string+ contains the error
        def error(string)
        end

        ###
        # Called when cdata blocks are found
        # [Parameters]
        # - +string+ contains the cdata content
        def cdata_block(string)
        end

        ###
        # Called when processing instructions are found
        # [Parameters]
        # - +name+ is the target of the instruction
        # - +content+ is the value of the instruction
        def processing_instruction(name, content)
        end
      end
    end
  end
end
