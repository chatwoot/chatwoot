# frozen_string_literal: true

module Nokogiri
  module XML
    class ProcessingInstruction < Node
      def initialize(document, name, content)
        super(document, name)
      end
    end
  end
end
