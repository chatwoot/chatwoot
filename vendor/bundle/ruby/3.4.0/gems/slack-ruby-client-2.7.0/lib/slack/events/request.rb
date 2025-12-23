# frozen_string_literal: true

module Slack
  module Events
    class Request
      class MissingSigningSecret < StandardError; end

      class TimestampExpired < StandardError; end

      class InvalidSignature < StandardError; end

      attr_reader :http_request,
                  :signing_secret,
                  :signature_expires_in

      def initialize(http_request, options = {})
        @http_request = http_request
        @signing_secret = options[:signing_secret] || Slack::Events.config.signing_secret
        @signature_expires_in =
          options[:signature_expires_in] || Slack::Events.config.signature_expires_in
      end

      # Request timestamp.
      def timestamp
        @timestamp ||= http_request.get_header('HTTP_X_SLACK_REQUEST_TIMESTAMP')
      end

      # The signature is created by combining the signing secret with the body of the request
      # Slack is sending using a standard HMAC-SHA256 keyed hash.
      def signature
        @signature ||= http_request.get_header('HTTP_X_SLACK_SIGNATURE')
      end

      # Signature version.
      def version
        'v0'
      end

      # Request body.
      def body
        @body ||= begin
          input = http_request.body
          input.rewind
          body = input.read
          input.rewind
          body
        end
      end

      # Returns true if the signature coming from Slack has expired.
      def expired?
        timestamp.nil? || (Time.now.to_i - timestamp.to_i).abs > signature_expires_in
      end

      # Returns true if the signature coming from Slack is valid.
      def valid?
        raise MissingSigningSecret unless signing_secret
        raise InvalidSignature unless signature

        digest = OpenSSL::Digest.new('SHA256')
        signature_basestring = [version, timestamp, body].join(':')
        hex_hash = OpenSSL::HMAC.hexdigest(digest, signing_secret, signature_basestring)
        computed_signature = [version, hex_hash].join('=')
        Utils::Security.secure_compare(computed_signature, signature)
      end

      # Validates the request signature and its expiration.
      def verify!
        raise TimestampExpired if expired?
        raise InvalidSignature unless valid?

        true
      end
    end
  end
end
