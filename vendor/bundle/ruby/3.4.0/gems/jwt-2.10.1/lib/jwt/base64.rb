# frozen_string_literal: true

require 'base64'

module JWT
  # Base64 encoding and decoding
  # @api private
  class Base64
    class << self
      # Encode a string with URL-safe Base64 complying with RFC 4648 (not padded).
      # @api private
      def url_encode(str)
        ::Base64.urlsafe_encode64(str, padding: false)
      end

      # Decode a string with URL-safe Base64 complying with RFC 4648.
      # Deprecated support for RFC 2045 remains for now. ("All line breaks or other characters not found in Table 1 must be ignored by decoding software")
      # @api private
      def url_decode(str)
        ::Base64.urlsafe_decode64(str)
      rescue ArgumentError => e
        raise unless e.message == 'invalid base64'
        raise Base64DecodeError, 'Invalid base64 encoding' if JWT.configuration.strict_base64_decoding

        loose_urlsafe_decode64(str).tap do
          Deprecations.warning('Invalid base64 input detected, could be because of invalid padding, trailing whitespaces or newline chars. Graceful handling of invalid input will be dropped in the next major version of ruby-jwt', only_if_valid: true)
        end
      end

      def loose_urlsafe_decode64(str)
        str += '=' * (4 - str.length.modulo(4))
        ::Base64.decode64(str.tr('-_', '+/'))
      end
    end
  end
end
