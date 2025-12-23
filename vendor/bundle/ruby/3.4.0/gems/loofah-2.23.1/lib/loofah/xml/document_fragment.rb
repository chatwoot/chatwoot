# frozen_string_literal: true

module Loofah
  module XML # :nodoc:
    #
    #  Subclass of Nokogiri::XML::DocumentFragment.
    #
    #  See Loofah::ScrubBehavior for additional methods.
    #
    class DocumentFragment < Nokogiri::XML::DocumentFragment
      class << self
        def parse(tags)
          doc = Loofah::XML::Document.new
          doc.encoding = tags.encoding.name if tags.respond_to?(:encoding)
          new(doc, tags)
        end
      end
    end
  end
end
