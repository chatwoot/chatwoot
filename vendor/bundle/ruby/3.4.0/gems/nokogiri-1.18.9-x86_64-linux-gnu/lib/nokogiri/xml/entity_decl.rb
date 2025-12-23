# frozen_string_literal: true

module Nokogiri
  module XML
    class EntityDecl < Nokogiri::XML::Node
      undef_method :attribute_nodes
      undef_method :attributes
      undef_method :namespace
      undef_method :namespace_definitions
      undef_method :line if method_defined?(:line)

      def self.new(name, doc, *args)
        doc.create_entity(name, *args)
      end

      private

      def inspect_attributes
        [:to_s]
      end
    end
  end
end
