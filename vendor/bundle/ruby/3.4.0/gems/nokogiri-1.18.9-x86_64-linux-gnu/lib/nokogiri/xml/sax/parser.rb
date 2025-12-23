# frozen_string_literal: true

module Nokogiri
  module XML
    module SAX
      ###
      # This parser is a SAX style parser that reads its input as it deems necessary. The parser
      # takes a Nokogiri::XML::SAX::Document, an optional encoding, then given an XML input, sends
      # messages to the Nokogiri::XML::SAX::Document.
      #
      # Here is an example of using this parser:
      #
      #   # Create a subclass of Nokogiri::XML::SAX::Document and implement
      #   # the events we care about:
      #   class MyHandler < Nokogiri::XML::SAX::Document
      #     def start_element name, attrs = []
      #       puts "starting: #{name}"
      #     end
      #
      #     def end_element name
      #       puts "ending: #{name}"
      #     end
      #   end
      #
      #   parser = Nokogiri::XML::SAX::Parser.new(MyHandler.new)
      #
      #   # Hand an IO object to the parser, which will read the XML from the IO.
      #   File.open(path_to_xml) do |f|
      #     parser.parse(f)
      #   end
      #
      # For more information about \SAX parsers, see Nokogiri::XML::SAX.
      #
      # Also see Nokogiri::XML::SAX::Document for the available events.
      #
      # For \HTML documents, use the subclass Nokogiri::HTML4::SAX::Parser.
      #
      class Parser
        # to dynamically resolve ParserContext in inherited methods
        include Nokogiri::ClassResolver

        # Structure used for marshalling attributes for some callbacks in XML::SAX::Document.
        class Attribute < Struct.new(:localname, :prefix, :uri, :value)
        end

        ENCODINGS = { # :nodoc:
          "NONE" => 0, # No char encoding detected
          "UTF-8" => 1, # UTF-8
          "UTF16LE" => 2, # UTF-16 little endian
          "UTF16BE" => 3, # UTF-16 big endian
          "UCS4LE" => 4, # UCS-4 little endian
          "UCS4BE" => 5, # UCS-4 big endian
          "EBCDIC" => 6, # EBCDIC uh!
          "UCS4-2143" => 7, # UCS-4 unusual ordering
          "UCS4-3412" => 8, # UCS-4 unusual ordering
          "UCS2" => 9, # UCS-2
          "ISO-8859-1" => 10, # ISO-8859-1 ISO Latin 1
          "ISO-8859-2" => 11, # ISO-8859-2 ISO Latin 2
          "ISO-8859-3" => 12, # ISO-8859-3
          "ISO-8859-4" => 13, # ISO-8859-4
          "ISO-8859-5" => 14, # ISO-8859-5
          "ISO-8859-6" => 15, # ISO-8859-6
          "ISO-8859-7" => 16, # ISO-8859-7
          "ISO-8859-8" => 17, # ISO-8859-8
          "ISO-8859-9" => 18, # ISO-8859-9
          "ISO-2022-JP" => 19, # ISO-2022-JP
          "SHIFT-JIS" => 20, # Shift_JIS
          "EUC-JP" => 21, # EUC-JP
          "ASCII" => 22, # pure ASCII
        }
        REVERSE_ENCODINGS = ENCODINGS.invert # :nodoc:
        deprecate_constant :ENCODINGS

        # The Nokogiri::XML::SAX::Document where events will be sent.
        attr_accessor :document

        # The encoding beings used for this document.
        attr_accessor :encoding

        ###
        # :call-seq:
        #   new ⇒ SAX::Parser
        #   new(handler) ⇒ SAX::Parser
        #   new(handler, encoding) ⇒ SAX::Parser
        #
        # Create a new Parser.
        #
        # [Parameters]
        # - +handler+ (optional Nokogiri::XML::SAX::Document) The document that will receive
        #   events. Will create a new Nokogiri::XML::SAX::Document if not given, which is accessible
        #   through the #document attribute.
        # - +encoding+ (optional Encoding, String, nil) An Encoding or encoding name to use when
        #   parsing the input. (default +nil+ for auto-detection)
        #
        def initialize(doc = Nokogiri::XML::SAX::Document.new, encoding = nil)
          @encoding = encoding
          @document = doc
          @warned   = false

          initialize_native unless Nokogiri.jruby?
        end

        ###
        # :call-seq:
        #   parse(input) { |parser_context| ... }
        #
        # Parse the input, sending events to the SAX::Document at #document.
        #
        # [Parameters]
        # - +input+ (String, IO) The input to parse.
        #
        # If +input+ quacks like a readable IO object, this method forwards to Parser.parse_io,
        # otherwise it forwards to Parser.parse_memory.
        #
        # [Yields]
        # If a block is given, the underlying ParserContext object will be yielded. This can be used
        # to set options on the parser context before parsing begins.
        #
        def parse(input, &block)
          if input.respond_to?(:read) && input.respond_to?(:close)
            parse_io(input, &block)
          else
            parse_memory(input, &block)
          end
        end

        ###
        # :call-seq:
        #   parse_io(io) { |parser_context| ... }
        #   parse_io(io, encoding) { |parser_context| ... }
        #
        # Parse an input stream.
        #
        # [Parameters]
        # - +io+ (IO) The readable IO object from which to read input
        # - +encoding+ (optional Encoding, String, nil) An Encoding or encoding name to use when
        #   parsing the input, or +nil+ for auto-detection. (default #encoding)
        #
        # [Yields]
        # If a block is given, the underlying ParserContext object will be yielded. This can be used
        # to set options on the parser context before parsing begins.
        #
        def parse_io(io, encoding = @encoding)
          ctx = related_class("ParserContext").io(io, encoding)
          yield ctx if block_given?
          ctx.parse_with(self)
        end

        ###
        # :call-seq:
        #   parse_memory(input) { |parser_context| ... }
        #   parse_memory(input, encoding) { |parser_context| ... }
        #
        # Parse an input string.
        #
        # [Parameters]
        # - +input+ (String) The input string to be parsed.
        # - +encoding+ (optional Encoding, String, nil) An Encoding or encoding name to use when
        #   parsing the input, or +nil+ for auto-detection. (default #encoding)
        #
        # [Yields]
        # If a block is given, the underlying ParserContext object will be yielded. This can be used
        # to set options on the parser context before parsing begins.
        #
        def parse_memory(input, encoding = @encoding)
          ctx = related_class("ParserContext").memory(input, encoding)
          yield ctx if block_given?
          ctx.parse_with(self)
        end

        ###
        # :call-seq:
        #   parse_file(filename) { |parser_context| ... }
        #   parse_file(filename, encoding) { |parser_context| ... }
        #
        # Parse a file.
        #
        # [Parameters]
        # - +filename+ (String) The path to the file to be parsed.
        # - +encoding+ (optional Encoding, String, nil) An Encoding or encoding name to use when
        #   parsing the input, or +nil+ for auto-detection. (default #encoding)
        #
        # [Yields]
        # If a block is given, the underlying ParserContext object will be yielded. This can be used
        # to set options on the parser context before parsing begins.
        #
        def parse_file(filename, encoding = @encoding)
          raise ArgumentError, "no filename provided" unless filename
          raise Errno::ENOENT unless File.exist?(filename)
          raise Errno::EISDIR if File.directory?(filename)

          ctx = related_class("ParserContext").file(filename, encoding)
          yield ctx if block_given?
          ctx.parse_with(self)
        end
      end
    end
  end
end
