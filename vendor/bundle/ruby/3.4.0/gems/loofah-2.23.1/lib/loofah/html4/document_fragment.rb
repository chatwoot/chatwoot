# frozen_string_literal: true

module Loofah
  module HTML4 # :nodoc:
    #
    #  Subclass of Nokogiri::HTML4::DocumentFragment.
    #
    #  See Loofah::ScrubBehavior and Loofah::TextBehavior for additional methods.
    #
    class DocumentFragment < Nokogiri::HTML4::DocumentFragment
      include Loofah::TextBehavior
      include Loofah::HtmlFragmentBehavior
    end
  end
end
