require 'geocoder/lookups/base'
require 'geocoder/results/test'

module Geocoder
  module Lookup
    class Test < Base

      def name
        "Test"
      end

      def self.add_stub(query_text, results)
        stubs[query_text] = results
      end

      def self.set_default_stub(results)
        @default_stub = results
      end

      def self.read_stub(query_text)
        @default_stub ||= nil
        stubs.fetch(query_text) {
          return @default_stub unless @default_stub.nil?
          raise ArgumentError, "unknown stub request #{query_text}"
        }
      end

      def self.stubs
        @stubs ||= {}
      end

      def self.delete_stub(query_text)
        stubs.delete(query_text)
      end

      def self.reset
        @stubs = {}
        @default_stub = nil
      end

      private

      def results(query)
        Geocoder::Lookup::Test.read_stub(query.text)
      end

    end
  end
end
