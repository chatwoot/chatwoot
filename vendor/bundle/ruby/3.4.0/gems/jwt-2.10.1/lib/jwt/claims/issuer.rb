# frozen_string_literal: true

module JWT
  module Claims
    # The Issuer class is responsible for validating the issuer claim ('iss') in a JWT token.
    class Issuer
      # Initializes a new Issuer instance.
      #
      # @param issuers [String, Symbol, Array<String, Symbol>] the expected issuer(s) for the JWT token.
      def initialize(issuers:)
        @issuers = Array(issuers).map { |item| item.is_a?(Symbol) ? item.to_s : item }
      end

      # Verifies the issuer claim ('iss') in the JWT token.
      #
      # @param context [Object] the context containing the JWT payload.
      # @param _args [Hash] additional arguments (not used).
      # @raise [JWT::InvalidIssuerError] if the issuer claim is invalid.
      # @return [nil]
      def verify!(context:, **_args)
        case (iss = context.payload['iss'])
        when *issuers
          nil
        else
          raise JWT::InvalidIssuerError, "Invalid issuer. Expected #{issuers}, received #{iss || '<none>'}"
        end
      end

      private

      attr_reader :issuers
    end
  end
end
