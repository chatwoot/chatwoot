# frozen_string_literal: true

module JWT
  module Configuration
    # The DecodeConfiguration class holds the configuration settings for decoding JWT tokens.
    class DecodeConfiguration
      # @!attribute [rw] verify_expiration
      #   @return [Boolean] whether to verify the expiration claim.
      # @!attribute [rw] verify_not_before
      #   @return [Boolean] whether to verify the not before claim.
      # @!attribute [rw] verify_iss
      #   @return [Boolean] whether to verify the issuer claim.
      # @!attribute [rw] verify_iat
      #   @return [Boolean] whether to verify the issued at claim.
      # @!attribute [rw] verify_jti
      #   @return [Boolean] whether to verify the JWT ID claim.
      # @!attribute [rw] verify_aud
      #   @return [Boolean] whether to verify the audience claim.
      # @!attribute [rw] verify_sub
      #   @return [Boolean] whether to verify the subject claim.
      # @!attribute [rw] leeway
      #   @return [Integer] the leeway in seconds for time-based claims.
      # @!attribute [rw] algorithms
      #   @return [Array<String>] the list of acceptable algorithms.
      # @!attribute [rw] required_claims
      #   @return [Array<String>] the list of required claims.

      attr_accessor :verify_expiration,
                    :verify_not_before,
                    :verify_iss,
                    :verify_iat,
                    :verify_jti,
                    :verify_aud,
                    :verify_sub,
                    :leeway,
                    :algorithms,
                    :required_claims

      # Initializes a new DecodeConfiguration instance with default settings.
      def initialize
        @verify_expiration = true
        @verify_not_before = true
        @verify_iss = false
        @verify_iat = false
        @verify_jti = false
        @verify_aud = false
        @verify_sub = false
        @leeway = 0
        @algorithms = ['HS256']
        @required_claims = []
      end

      # @api private
      def to_h
        {
          verify_expiration: verify_expiration,
          verify_not_before: verify_not_before,
          verify_iss: verify_iss,
          verify_iat: verify_iat,
          verify_jti: verify_jti,
          verify_aud: verify_aud,
          verify_sub: verify_sub,
          leeway: leeway,
          algorithms: algorithms,
          required_claims: required_claims
        }
      end
    end
  end
end
