# frozen_string_literal: true

module JWT
  module Claims
    # The JwtId class is responsible for validating the JWT ID claim ('jti') in a JWT token.
    class JwtId
      # Initializes a new JwtId instance.
      #
      # @param validator [#call] an object responding to `call` to validate the JWT ID.
      def initialize(validator:)
        @validator = validator
      end

      # Verifies the JWT ID claim ('jti') in the JWT token.
      #
      # @param context [Object] the context containing the JWT payload.
      # @param _args [Hash] additional arguments (not used).
      # @raise [JWT::InvalidJtiError] if the JWT ID claim is invalid or missing.
      # @return [nil]
      def verify!(context:, **_args)
        jti = context.payload['jti']
        if validator.respond_to?(:call)
          verified = validator.arity == 2 ? validator.call(jti, context.payload) : validator.call(jti)
          raise(JWT::InvalidJtiError, 'Invalid jti') unless verified
        elsif jti.to_s.strip.empty?
          raise(JWT::InvalidJtiError, 'Missing jti')
        end
      end

      private

      attr_reader :validator
    end
  end
end
