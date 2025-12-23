# frozen_string_literal: true

module Aws
  module EventStream
    class Message

      def initialize(options)
        @headers = options[:headers] || {}
        @payload = options[:payload] || StringIO.new
      end

      # @return [Hash] headers of a message
      attr_reader :headers

      # @return [IO] payload of a message, size not exceed 16MB.
      #   StringIO is returned for <= 1MB payload
      #   Tempfile is returned for > 1MB payload
      attr_reader :payload

    end
  end
end
