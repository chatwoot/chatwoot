# coding: utf-8
# frozen_string_literal: true

#
#  Copyright 2013-2021 Sam Ruby, Stephen Checkoway
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require_relative "../html4/document"

module Nokogiri
  module HTML5
    # Enum for the HTML5 parser quirks mode values. Values returned by HTML5::Document#quirks_mode
    #
    # See https://dom.spec.whatwg.org/#concept-document-quirks for more information on HTML5 quirks
    # mode.
    #
    # Since v1.14.0
    module QuirksMode
      NO_QUIRKS = 0 # The document was parsed in "no-quirks" mode
      QUIRKS = 1 # The document was parsed in "quirks" mode
      LIMITED_QUIRKS = 2 # The document was parsed in "limited-quirks" mode
    end

    # Since v1.12.0
    #
    # 💡 HTML5 functionality is not available when running JRuby.
    class Document < Nokogiri::HTML4::Document
      # Get the url name for this document, as passed into Document.parse, Document.read_io, or
      # Document.read_memory
      attr_reader :url

      # Get the parser's quirks mode value. See HTML5::QuirksMode.
      #
      # This method returns +nil+ if the parser was not invoked (e.g., Nokogiri::HTML5::Document.new).
      #
      # Since v1.14.0
      attr_reader :quirks_mode

      class << self
        # :call-seq:
        #   parse(input) { |options| ... } → HTML5::Document
        #   parse(input, url: encoding:) { |options| ... } → HTML5::Document
        #   parse(input, **options) → HTML5::Document
        #
        # Parse \HTML input with a parser compliant with the HTML5 spec. This method uses the
        # encoding of +input+ if it can be determined, or else falls back to the +encoding:+
        # parameter.
        #
        # [Required Parameters]
        # - +input+ (String | IO) the \HTML content to be parsed.
        #
        # [Optional Parameters]
        # - +url:+ (String) the base URI of the document.
        #
        # [Optional Keyword Arguments]
        # - +encoding:+ (Encoding) The name of the encoding that should be used when processing the
        #   document. When not provided, the encoding will be determined based on the document
        #   content.
        #
        # - +max_errors:+ (Integer) The maximum number of parse errors to record. (default
        #   +Nokogiri::Gumbo::DEFAULT_MAX_ERRORS+ which is currently 0)
        #
        # - +max_tree_depth:+ (Integer) The maximum depth of the parse tree. (default
        #   +Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH+)
        #
        # - +max_attributes:+ (Integer) The maximum number of attributes allowed on an
        #   element. (default +Nokogiri::Gumbo::DEFAULT_MAX_ATTRIBUTES+)
        #
        # - +parse_noscript_content_as_text:+ (Boolean) Whether to parse the content of +noscript+
        #   elements as text. (default +false+)
        #
        # See rdoc-ref:HTML5@Parsing+options for a complete description of these parsing options.
        #
        # [Yields]
        #   If present, the block will be passed a Hash object to modify with parse options before the
        #   input is parsed. See rdoc-ref:HTML5@Parsing+options for a list of available options.
        #
        #   ⚠ Note that +url:+ and +encoding:+ cannot be set by the configuration block.
        #
        # [Returns] Nokogiri::HTML5::Document
        #
        # *Example:* Parse a string with a specific encoding and custom max errors limit.
        #
        #   Nokogiri::HTML5::Document.parse(socket, encoding: "ISO-8859-1", max_errors: 10)
        #
        # *Example:* Parse a string setting the +:parse_noscript_content_as_text+ option using the
        # configuration block parameter.
        #
        #   Nokogiri::HTML5::Document.parse(input) { |c| c[:parse_noscript_content_as_text] = true }
        #
        def parse(
          string_or_io,
          url_ = nil, encoding_ = nil,
          url: url_, encoding: encoding_,
          **options, &block
        )
          yield options if block
          string_or_io = "" unless string_or_io

          if string_or_io.respond_to?(:encoding) && string_or_io.encoding != Encoding::ASCII_8BIT
            encoding ||= string_or_io.encoding.name
          end

          if string_or_io.respond_to?(:read) && string_or_io.respond_to?(:path)
            url ||= string_or_io.path
          end
          unless string_or_io.respond_to?(:read) || string_or_io.respond_to?(:to_str)
            raise ArgumentError, "not a string or IO object"
          end

          do_parse(string_or_io, url, encoding, **options)
        end

        # Create a new document from an IO object.
        #
        # 💡 Most users should prefer Document.parse to this method.
        def read_io(io, url_ = nil, encoding_ = nil, url: url_, encoding: encoding_, **options)
          raise ArgumentError, "io object doesn't respond to :read" unless io.respond_to?(:read)

          do_parse(io, url, encoding, **options)
        end

        # Create a new document from a String.
        #
        # 💡 Most users should prefer Document.parse to this method.
        def read_memory(string, url_ = nil, encoding_ = nil, url: url_, encoding: encoding_, **options)
          raise ArgumentError, "string object doesn't respond to :to_str" unless string.respond_to?(:to_str)

          do_parse(string, url, encoding, **options)
        end

        private

        def do_parse(string_or_io, url, encoding, **options)
          string = HTML5.read_and_encode(string_or_io, encoding)

          options[:max_attributes] ||= Nokogiri::Gumbo::DEFAULT_MAX_ATTRIBUTES
          options[:max_errors] ||= options.delete(:max_parse_errors) || Nokogiri::Gumbo::DEFAULT_MAX_ERRORS
          options[:max_tree_depth] ||= Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH

          doc = Nokogiri::Gumbo.parse(string, url, self, **options)
          doc.encoding = "UTF-8"
          doc
        end
      end

      def initialize(*args) # :nodoc:
        super
        @url = nil
        @quirks_mode = nil
      end

      # :call-seq:
      #   fragment() → Nokogiri::HTML5::DocumentFragment
      #   fragment(markup) → Nokogiri::HTML5::DocumentFragment
      #
      # Parse a HTML5 document fragment from +markup+, returning a Nokogiri::HTML5::DocumentFragment.
      #
      # [Properties]
      # - +markup+ (String) The HTML5 markup fragment to be parsed
      #
      # [Returns]
      #   Nokogiri::HTML5::DocumentFragment. This object's children will be empty if +markup+ is not
      #   passed, is empty, or is +nil+.
      #
      def fragment(markup = nil)
        DocumentFragment.new(self, markup)
      end

      def to_xml(options = {}, &block) # :nodoc:
        # Bypass XML::Document#to_xml which doesn't add
        # XML::Node::SaveOptions::AS_XML like XML::Node#to_xml does.
        XML::Node.instance_method(:to_xml).bind_call(self, options, &block)
      end

      # :call-seq:
      #   xpath_doctype() → Nokogiri::CSS::XPathVisitor::DoctypeConfig
      #
      # [Returns] The document type which determines CSS-to-XPath translation.
      #
      # See CSS::XPathVisitor for more information.
      def xpath_doctype
        Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML5
      end
    end
  end
end
