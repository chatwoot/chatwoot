# frozen_string_literal: true

module JWT
  module Claims
    # The Required class is responsible for validating that all required claims are present in a JWT token.
    class Required
      # Initializes a new Required instance.
      #
      # @param required_claims [Array<String>] the list of required claims.
      def initialize(required_claims:)
        @required_claims = required_claims
      end

      # Verifies that all required claims are present in the JWT payload.
      #
      # @param context [Object] the context containing the JWT payload.
      # @param _args [Hash] additional arguments (not used).
      # @raise [JWT::MissingRequiredClaim] if any required claim is missing.
      # @return [nil]
      def verify!(context:, **_args)
        required_claims.each do |required_claim|
          next if context.payload.is_a?(Hash) && context.payload.key?(required_claim)

          raise JWT::MissingRequiredClaim, "Missing required claim #{required_claim}"
        end
      end

      private

      attr_reader :required_claims
    end
  end
end
