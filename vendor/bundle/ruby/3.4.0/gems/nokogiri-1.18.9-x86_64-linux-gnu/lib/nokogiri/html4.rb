# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  class << self
    # Convenience method for Nokogiri::HTML4::Document.parse
    def HTML4(...)
      Nokogiri::HTML4::Document.parse(...)
    end
  end

  # Since v1.12.0
  #
  # 💡 Before v1.12.0, Nokogiri::HTML4 did not exist, and Nokogiri::HTML was the module/namespace
  # for parsing HTML.
  module HTML4
    class << self
      # Convenience method for Nokogiri::HTML4::Document.parse
      def parse(...)
        Document.parse(...)
      end

      # Convenience method for Nokogiri::HTML4::DocumentFragment.parse
      def fragment(...)
        HTML4::DocumentFragment.parse(...)
      end
    end

    # Instance of Nokogiri::HTML4::EntityLookup
    NamedCharacters = EntityLookup.new
  end
end

require_relative "html4/entity_lookup"
require_relative "html4/document"
require_relative "html4/document_fragment"
require_relative "html4/encoding_reader"
require_relative "html4/sax/parser_context"
require_relative "html4/sax/parser"
require_relative "html4/sax/push_parser"
require_relative "html4/element_description"
require_relative "html4/element_description_defaults"
