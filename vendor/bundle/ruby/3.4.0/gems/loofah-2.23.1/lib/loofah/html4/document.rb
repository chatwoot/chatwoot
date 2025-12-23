# frozen_string_literal: true

module Loofah
  module HTML4 # :nodoc:
    #
    #  Subclass of Nokogiri::HTML4::Document.
    #
    #  See Loofah::ScrubBehavior and Loofah::TextBehavior for additional methods.
    #
    class Document < Nokogiri::HTML4::Document
      include Loofah::ScrubBehavior::Node
      include Loofah::DocumentDecorator
      include Loofah::TextBehavior
      include Loofah::HtmlDocumentBehavior
    end
  end
end
