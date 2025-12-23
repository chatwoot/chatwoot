# frozen_string_literal: true

module Nokogiri
  module XML
    class XPathContext
      ###
      # Register namespaces in +namespaces+
      def register_namespaces(namespaces)
        namespaces.each do |key, value|
          key = key.to_s.gsub(/.*:/, "") # strip off 'xmlns:' or 'xml:'

          register_ns(key, value)
        end
      end

      def register_variables(binds)
        return if binds.nil?

        binds.each do |key, value|
          key = key.to_s

          register_variable(key, value)
        end
      end
    end
  end
end
