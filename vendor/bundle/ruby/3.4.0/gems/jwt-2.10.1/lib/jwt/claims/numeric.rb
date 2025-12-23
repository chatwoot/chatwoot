# frozen_string_literal: true

module JWT
  module Claims
    # The Numeric class is responsible for validating numeric claims in a JWT token.
    # The numeric claims are: exp, iat and nbf
    class Numeric
      # The Compat class provides backward compatibility for numeric claim validation.
      # @api private
      class Compat
        def initialize(payload)
          @payload = payload
        end

        def verify!
          JWT::Claims.verify_payload!(@payload, :numeric)
        end
      end

      # List of numeric claims that can be validated.
      NUMERIC_CLAIMS = %i[
        exp
        iat
        nbf
      ].freeze

      private_constant(:NUMERIC_CLAIMS)

      # @api private
      def self.new(*args)
        return super if args.empty?

        Deprecations.warning('Calling ::JWT::Claims::Numeric.new with the payload will be removed in the next major version of ruby-jwt')
        Compat.new(*args)
      end

      # Verifies the numeric claims in the JWT context.
      #
      # @param context [Object] the context containing the JWT payload.
      # @raise [JWT::InvalidClaimError] if any numeric claim is invalid.
      # @return [nil]
      def verify!(context:)
        validate_numeric_claims(context.payload)
      end

      # Verifies the numeric claims in the JWT payload.
      #
      # @param payload [Hash] the JWT payload containing the claims.
      # @param _args [Hash] additional arguments (not used).
      # @raise [JWT::InvalidClaimError] if any numeric claim is invalid.
      # @return [nil]
      # @deprecated The ::JWT::Claims::Numeric.verify! method will be removed in the next major version of ruby-jwt
      def self.verify!(payload:, **_args)
        Deprecations.warning('The ::JWT::Claims::Numeric.verify! method will be removed in the next major version of ruby-jwt.')
        JWT::Claims.verify_payload!(payload, :numeric)
      end

      private

      def validate_numeric_claims(payload)
        NUMERIC_CLAIMS.each do |claim|
          validate_is_numeric(payload, claim)
        end
      end

      def validate_is_numeric(payload, claim)
        return unless payload.is_a?(Hash)
        return unless payload.key?(claim) ||
                      payload.key?(claim.to_s)

        return if payload[claim].is_a?(::Numeric) || payload[claim.to_s].is_a?(::Numeric)

        raise InvalidPayload, "#{claim} claim must be a Numeric value but it is a #{(payload[claim] || payload[claim.to_s]).class}"
      end
    end
  end
end
