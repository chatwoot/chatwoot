# frozen_string_literal: true

module Loofah
  module HTML5 # :nodoc:
    #
    #  Subclass of Nokogiri::HTML5::Document.
    #
    #  See Loofah::ScrubBehavior and Loofah::TextBehavior for additional methods.
    #
    class Document < Nokogiri::HTML5::Document
      include Loofah::ScrubBehavior::Node
      include Loofah::DocumentDecorator
      include Loofah::TextBehavior
      include Loofah::HtmlDocumentBehavior
    end
  end
end
