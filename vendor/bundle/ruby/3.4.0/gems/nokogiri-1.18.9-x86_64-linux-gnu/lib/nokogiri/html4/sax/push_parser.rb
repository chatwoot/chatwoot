# frozen_string_literal: true

module Nokogiri
  module HTML4
    module SAX
      class PushParser
        # The Nokogiri::HTML4::SAX::Document on which the PushParser will be
        # operating
        attr_accessor :document

        def initialize(doc = HTML4::SAX::Document.new, file_name = nil, encoding = "UTF-8")
          @document = doc
          @encoding = encoding
          @sax_parser = HTML4::SAX::Parser.new(doc, @encoding)

          ## Create our push parser context
          initialize_native(@sax_parser, file_name, encoding)
        end

        ###
        # Write a +chunk+ of HTML to the PushParser.  Any callback methods
        # that can be called will be called immediately.
        def write(chunk, last_chunk = false)
          native_write(chunk, last_chunk)
        end
        alias_method :<<, :write

        ###
        # Finish the parsing.  This method is only necessary for
        # Nokogiri::HTML4::SAX::Document#end_document to be called.
        def finish
          write("", true)
        end
      end
    end
  end
end
