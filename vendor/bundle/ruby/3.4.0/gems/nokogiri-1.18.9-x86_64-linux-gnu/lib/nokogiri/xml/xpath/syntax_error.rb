# frozen_string_literal: true

module Nokogiri
  module XML
    module XPath
      class SyntaxError < XML::SyntaxError
        def to_s
          [super.chomp, str1].compact.join(": ")
        end
      end
    end
  end
end
