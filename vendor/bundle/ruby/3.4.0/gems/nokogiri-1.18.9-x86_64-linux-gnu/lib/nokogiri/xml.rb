# frozen_string_literal: true

module Nokogiri
  class << self
    # Convenience method for Nokogiri::XML::Document.parse
    def XML(...)
      Nokogiri::XML::Document.parse(...)
    end
  end

  module XML
    # Original C14N 1.0 spec canonicalization
    XML_C14N_1_0 = 0
    # Exclusive C14N 1.0 spec canonicalization
    XML_C14N_EXCLUSIVE_1_0 = 1
    # C14N 1.1 spec canonicalization
    XML_C14N_1_1 = 2

    class << self
      # Convenience method for Nokogiri::XML::Reader.new
      def Reader(...)
        Reader.new(...)
      end

      # Convenience method for Nokogiri::XML::Document.parse
      def parse(...)
        Document.parse(...)
      end

      # Convenience method for Nokogiri::XML::DocumentFragment.parse
      def fragment(...)
        XML::DocumentFragment.parse(...)
      end
    end
  end
end

require_relative "xml/pp"
require_relative "xml/parse_options"
require_relative "xml/sax"
require_relative "xml/searchable"
require_relative "xml/node"
require_relative "xml/attribute_decl"
require_relative "xml/element_decl"
require_relative "xml/element_content"
require_relative "xml/character_data"
require_relative "xml/namespace"
require_relative "xml/attr"
require_relative "xml/dtd"
require_relative "xml/cdata"
require_relative "xml/text"
require_relative "xml/document"
require_relative "xml/document_fragment"
require_relative "xml/processing_instruction"
require_relative "xml/node_set"
require_relative "xml/syntax_error"
require_relative "xml/xpath"
require_relative "xml/xpath_context"
require_relative "xml/builder"
require_relative "xml/reader"
require_relative "xml/notation"
require_relative "xml/entity_decl"
require_relative "xml/entity_reference"
require_relative "xml/schema"
require_relative "xml/relax_ng"
