# frozen_string_literal: true

module Nokogiri
  module XML
    ###
    # SAX Parsers are event-driven parsers.
    #
    # Two SAX parsers for XML are available, a parser that reads from a string or IO object as it
    # feels necessary, and a parser that you explicitly feed XML in chunks. If you want to let
    # Nokogiri deal with reading your XML, use the Nokogiri::XML::SAX::Parser. If you want to have
    # fine grain control over the XML input, use the Nokogiri::XML::SAX::PushParser.
    #
    # If you want to do SAX style parsing of HTML, check out Nokogiri::HTML4::SAX.
    #
    # The basic way a SAX style parser works is by creating a parser, telling the parser about the
    # events we're interested in, then giving the parser some XML to process. The parser will notify
    # you when it encounters events you said you would like to know about.
    #
    # To register for events, subclass Nokogiri::XML::SAX::Document and implement the methods for
    # which you would like notification.
    #
    # For example, if I want to be notified when a document ends, and when an element starts, I
    # would write a class like this:
    #
    #   class MyHandler < Nokogiri::XML::SAX::Document
    #     def end_document
    #       puts "the document has ended"
    #     end
    #
    #     def start_element name, attributes = []
    #       puts "#{name} started"
    #     end
    #   end
    #
    # Then I would instantiate a SAX parser with this document, and feed the parser some XML
    #
    #   # Create a new parser
    #   parser = Nokogiri::XML::SAX::Parser.new(MyHandler.new)
    #
    #   # Feed the parser some XML
    #   parser.parse(File.open(ARGV[0]))
    #
    # Now my document handler will be called when each node starts, and when then document ends. To
    # see what kinds of events are available, take a look at Nokogiri::XML::SAX::Document.
    #
    module SAX
    end
  end
end

require_relative "sax/document"
require_relative "sax/parser_context"
require_relative "sax/parser"
require_relative "sax/push_parser"
