# frozen_string_literal: true

module Nokogiri
  module HTML4
    ###
    # Nokogiri provides a SAX parser to process HTML4 which will provide HTML recovery
    # ("autocorrection") features.
    #
    # See Nokogiri::HTML4::SAX::Parser for a basic example of using a SAX parser with HTML.
    #
    # For more information on SAX parsers, see Nokogiri::XML::SAX
    #
    module SAX
      ###
      # This parser is a SAX style parser that reads its input as it deems necessary. The parser
      # takes a Nokogiri::XML::SAX::Document, an optional encoding, then given an HTML input, sends
      # messages to the Nokogiri::XML::SAX::Document.
      #
      # ⚠ This is an HTML4 parser and so may not support some HTML5 features and behaviors.
      #
      # Here is a basic usage example:
      #
      #   class MyHandler < Nokogiri::XML::SAX::Document
      #     def start_element name, attributes = []
      #       puts "found a #{name}"
      #     end
      #   end
      #
      #   parser = Nokogiri::HTML4::SAX::Parser.new(MyHandler.new)
      #
      #   # Hand an IO object to the parser, which will read the HTML from the IO.
      #   File.open(path_to_html) do |f|
      #     parser.parse(f)
      #   end
      #
      # For more information on \SAX parsers, see Nokogiri::XML::SAX or the parent class
      # Nokogiri::XML::SAX::Parser.
      #
      # Also see Nokogiri::XML::SAX::Document for the available events.
      #
      class Parser < Nokogiri::XML::SAX::Parser
        # this class inherits its behavior from Nokogiri::XML::SAX::Parser, but note that superclass
        # uses Nokogiri::ClassResolver to use HTML4::SAX::ParserContext as the context class for
        # this class, which is where the real behavioral differences are implemented.
      end
    end
  end
end
