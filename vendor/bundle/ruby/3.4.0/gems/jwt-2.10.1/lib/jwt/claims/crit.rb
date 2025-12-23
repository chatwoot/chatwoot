# frozen_string_literal: true

module JWT
  module Claims
    # Responsible of validation the crit header
    class Crit
      # Initializes a new Crit instance.
      #
      # @param expected_crits [String] the expected crit header values for the JWT token.
      def initialize(expected_crits:)
        @expected_crits = Array(expected_crits)
      end

      # Verifies the critical claim ('crit') in the JWT token header.
      #
      # @param context [Object] the context containing the JWT payload and header.
      # @param _args [Hash] additional arguments (not used).
      # @raise [JWT::InvalidCritError] if the crit claim is invalid.
      # @return [nil]
      def verify!(context:, **_args)
        raise(JWT::InvalidCritError, 'Crit header missing') unless context.header['crit']
        raise(JWT::InvalidCritError, 'Crit header should be an array') unless context.header['crit'].is_a?(Array)

        missing = (expected_crits - context.header['crit'])
        raise(JWT::InvalidCritError, "Crit header missing expected values: #{missing.join(', ')}") if missing.any?

        nil
      end

      private

      attr_reader :expected_crits
    end
  end
end
