# frozen_string_literal: true

module Aws
  module Endpoints
    class Endpoint
      def initialize(url:, properties: {}, headers: {})
        @url = url
        @properties = properties
        @headers = headers
      end

      attr_reader :url
      attr_reader :properties
      attr_reader :headers
    end
  end
end
