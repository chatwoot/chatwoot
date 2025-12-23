# frozen_string_literal: true

module JWT
  module Claims
    # The Expiration class is responsible for validating the expiration claim ('exp') in a JWT token.
    class Expiration
      # Initializes a new Expiration instance.
      #
      # @param leeway [Integer] the amount of leeway (in seconds) to allow when validating the expiration time. Default: 0.
      def initialize(leeway:)
        @leeway = leeway || 0
      end

      # Verifies the expiration claim ('exp') in the JWT token.
      #
      # @param context [Object] the context containing the JWT payload.
      # @param _args [Hash] additional arguments (not used).
      # @raise [JWT::ExpiredSignature] if the token has expired.
      # @return [nil]
      def verify!(context:, **_args)
        return unless context.payload.is_a?(Hash)
        return unless context.payload.key?('exp')

        raise JWT::ExpiredSignature, 'Signature has expired' if context.payload['exp'].to_i <= (Time.now.to_i - leeway)
      end

      private

      attr_reader :leeway
    end
  end
end
