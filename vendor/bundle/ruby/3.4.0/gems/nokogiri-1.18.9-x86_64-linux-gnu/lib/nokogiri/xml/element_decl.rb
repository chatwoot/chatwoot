# frozen_string_literal: true

module Nokogiri
  module XML
    class ElementDecl < Nokogiri::XML::Node
      undef_method :namespace
      undef_method :namespace_definitions
      undef_method :line if method_defined?(:line)

      private

      def inspect_attributes
        [:to_s]
      end
    end
  end
end
