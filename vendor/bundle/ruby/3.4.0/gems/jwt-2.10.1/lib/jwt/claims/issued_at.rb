# frozen_string_literal: true

module JWT
  module Claims
    # The IssuedAt class is responsible for validating the issued at claim ('iat') in a JWT token.
    class IssuedAt
      # Verifies the issued at claim ('iat') in the JWT token.
      #
      # @param context [Object] the context containing the JWT payload.
      # @param _args [Hash] additional arguments (not used).
      # @raise [JWT::InvalidIatError] if the issued at claim is invalid.
      # @return [nil]
      def verify!(context:, **_args)
        return unless context.payload.is_a?(Hash)
        return unless context.payload.key?('iat')

        iat = context.payload['iat']
        raise(JWT::InvalidIatError, 'Invalid iat') if !iat.is_a?(::Numeric) || iat.to_f > Time.now.to_f
      end
    end
  end
end
