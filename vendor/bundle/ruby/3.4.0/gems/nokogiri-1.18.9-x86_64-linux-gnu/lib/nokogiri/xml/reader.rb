# frozen_string_literal: true

module Nokogiri
  module XML
    ###
    # The Reader parser allows you to effectively pull parse an \XML document.  Once instantiated,
    # call Nokogiri::XML::Reader#each to iterate over each node.
    #
    # Nokogiri::XML::Reader parses an \XML document similar to the way a cursor would move. The
    # Reader is given an \XML document, and yields nodes to an each block.
    #
    # The Reader parser might be good for when you need the speed and low memory usage of a \SAX
    # parser, but do not want to write a SAX::Document handler.
    #
    # Here is an example of usage:
    #
    #     reader = Nokogiri::XML::Reader.new <<~XML
    #       <x xmlns:tenderlove='http://tenderlovemaking.com/'>
    #         <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    #       </x>
    #     XML
    #
    #     reader.each do |node|
    #       # node is an instance of Nokogiri::XML::Reader
    #       puts node.name
    #     end
    #
    # ⚠ Nokogiri::XML::Reader#each can only be called once! Once the cursor moves through the entire
    # document, you must parse the document again. It may be better to capture all information you
    # need during a single iteration.
    #
    # ⚠ libxml2 does not support error recovery in the Reader parser. The +RECOVER+ ParseOption is
    # ignored. If a syntax error is encountered during parsing, an exception will be raised.
    class Reader
      include Enumerable

      TYPE_NONE = 0
      # Element node type
      TYPE_ELEMENT = 1
      # Attribute node type
      TYPE_ATTRIBUTE = 2
      # Text node type
      TYPE_TEXT = 3
      # CDATA node type
      TYPE_CDATA = 4
      # Entity Reference node type
      TYPE_ENTITY_REFERENCE = 5
      # Entity node type
      TYPE_ENTITY = 6
      # PI node type
      TYPE_PROCESSING_INSTRUCTION = 7
      # Comment node type
      TYPE_COMMENT = 8
      # Document node type
      TYPE_DOCUMENT = 9
      # Document Type node type
      TYPE_DOCUMENT_TYPE = 10
      # Document Fragment node type
      TYPE_DOCUMENT_FRAGMENT = 11
      # Notation node type
      TYPE_NOTATION = 12
      # Whitespace node type
      TYPE_WHITESPACE = 13
      # Significant Whitespace node type
      TYPE_SIGNIFICANT_WHITESPACE = 14
      # Element end node type
      TYPE_END_ELEMENT = 15
      # Entity end node type
      TYPE_END_ENTITY = 16
      # \XML Declaration node type
      TYPE_XML_DECLARATION = 17

      # A list of errors encountered while parsing
      attr_accessor :errors

      # The \XML source
      attr_reader :source

      alias_method :self_closing?, :empty_element?

      # :call-seq:
      #   Reader.new(input) { |options| ... } → Reader
      #   Reader.new(input, url:, encoding:, options:) { |options| ... } → Reader
      #
      # Create a new Reader to parse an \XML document.
      #
      # [Required Parameters]
      # - +input+ (String | IO): The \XML document to parse.
      #
      # [Optional Parameters]
      # - +url:+ (String) The base URL of the document.
      # - +encoding:+ (String) The name of the encoding of the document.
      # - +options:+ (Integer | ParseOptions) Options to control the parser behavior.
      #   Defaults to +ParseOptions::STRICT+.
      #
      # [Yields]
      # If present, the block will be passed a Nokogiri::XML::ParseOptions object to modify before
      # the fragment is parsed. See Nokogiri::XML::ParseOptions for more information.
      def self.new(
        string_or_io,
        url_ = nil, encoding_ = nil, options_ = ParseOptions::STRICT,
        url: url_, encoding: encoding_, options: options_
      )
        options = Nokogiri::XML::ParseOptions.new(options) if Integer === options
        yield options if block_given?

        if string_or_io.respond_to?(:read)
          return Reader.from_io(string_or_io, url, encoding, options.to_i)
        end

        Reader.from_memory(string_or_io, url, encoding, options.to_i)
      end

      private def initialize(source, url = nil, encoding = nil) # :nodoc:
        @source   = source
        @errors   = []
        @encoding = encoding
      end

      # Get the attributes and namespaces of the current node as a Hash.
      #
      # This is the union of Reader#attribute_hash and Reader#namespaces
      #
      # [Returns]
      #   (Hash<String, String>) Attribute names and values, and namespace prefixes and hrefs.
      def attributes
        attribute_hash.merge(namespaces)
      end

      ###
      # Move the cursor through the document yielding the cursor to the block
      def each
        while (cursor = read)
          yield cursor
        end
      end
    end
  end
end
