# frozen_string_literal: true

require_relative 'claims/audience'
require_relative 'claims/crit'
require_relative 'claims/decode_verifier'
require_relative 'claims/expiration'
require_relative 'claims/issued_at'
require_relative 'claims/issuer'
require_relative 'claims/jwt_id'
require_relative 'claims/not_before'
require_relative 'claims/numeric'
require_relative 'claims/required'
require_relative 'claims/subject'
require_relative 'claims/verification_methods'
require_relative 'claims/verifier'

module JWT
  # JWT Claim verifications
  # https://datatracker.ietf.org/doc/html/rfc7519#section-4
  #
  # Verification is supported for the following claims:
  # exp
  # nbf
  # iss
  # iat
  # jti
  # aud
  # sub
  # required
  # numeric
  module Claims
    # Represents a claim verification error
    Error = Struct.new(:message, keyword_init: true)

    class << self
      # @deprecated Use {verify_payload!} instead. Will be removed in the next major version of ruby-jwt.
      def verify!(payload, options)
        Deprecations.warning('The ::JWT::Claims.verify! method is deprecated will be removed in the next major version of ruby-jwt')
        DecodeVerifier.verify!(payload, options)
      end

      # Checks if the claims in the JWT payload are valid.
      # @example
      #
      #   ::JWT::Claims.verify_payload!({"exp" => Time.now.to_i + 10}, :exp)
      #   ::JWT::Claims.verify_payload!({"exp" => Time.now.to_i - 10}, exp: { leeway: 11})
      #
      # @param payload [Hash] the JWT payload.
      # @param options [Array] the options for verifying the claims.
      # @return [void]
      # @raise [JWT::DecodeError] if any claim is invalid.
      def verify_payload!(payload, *options)
        Verifier.verify!(VerificationContext.new(payload: payload), *options)
      end

      # Checks if the claims in the JWT payload are valid.
      #
      # @param payload [Hash] the JWT payload.
      # @param options [Array] the options for verifying the claims.
      # @return [Boolean] true if the claims are valid, false otherwise
      def valid_payload?(payload, *options)
        payload_errors(payload, *options).empty?
      end

      # Returns the errors in the claims of the JWT token.
      #
      # @param options [Array] the options for verifying the claims.
      # @return [Array<JWT::Claims::Error>] the errors in the claims of the JWT
      def payload_errors(payload, *options)
        Verifier.errors(VerificationContext.new(payload: payload), *options)
      end
    end
  end
end
