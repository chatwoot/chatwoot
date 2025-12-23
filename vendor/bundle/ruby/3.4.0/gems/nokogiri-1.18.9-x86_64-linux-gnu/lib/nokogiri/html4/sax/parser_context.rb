# frozen_string_literal: true

module Nokogiri
  module HTML4
    module SAX
      ###
      # Context object to invoke the HTML4 SAX parser on the SAX::Document handler.
      #
      # 💡 This class is usually not instantiated by the user. Use Nokogiri::HTML4::SAX::Parser
      # instead.
      class ParserContext < Nokogiri::XML::SAX::ParserContext
      end
    end
  end
end
