# frozen_string_literal: true

module Faraday
  module Multipart
    # Multipart value used to POST data with a content type.
    class ParamPart
      # @param value [String] Uploaded content as a String.
      # @param content_type [String] String content type of the value.
      # @param content_id [String] Optional String of this value's Content-ID.
      #
      # @return [Faraday::ParamPart]
      def initialize(value, content_type, content_id = nil)
        @value = value
        @content_type = content_type
        @content_id = content_id
      end

      # Converts this value to a form part.
      #
      # @param boundary [String] String multipart boundary that must not exist in
      #   the content exactly.
      # @param key [String] String key name for this value.
      #
      # @return [Faraday::Parts::Part]
      def to_part(boundary, key)
        Faraday::Multipart::Parts::Part.new(boundary, key, value, headers)
      end

      # Returns a Hash of String key/value pairs.
      #
      # @return [Hash]
      def headers
        {
          'Content-Type' => content_type,
          'Content-ID' => content_id
        }
      end

      # The content to upload.
      #
      # @return [String]
      attr_reader :value

      # The value's content type.
      #
      # @return [String]
      attr_reader :content_type

      # The value's content ID, if given.
      #
      # @return [String, nil]
      attr_reader :content_id
    end
  end
end
