# frozen_string_literal: true

module JWT
  module Claims
    # The Audience class is responsible for validating the audience claim ('aud') in a JWT token.
    class Audience
      # Initializes a new Audience instance.
      #
      # @param expected_audience [String, Array<String>] the expected audience(s) for the JWT token.
      def initialize(expected_audience:)
        @expected_audience = expected_audience
      end

      # Verifies the audience claim ('aud') in the JWT token.
      #
      # @param context [Object] the context containing the JWT payload.
      # @param _args [Hash] additional arguments (not used).
      # @raise [JWT::InvalidAudError] if the audience claim is invalid.
      # @return [nil]
      def verify!(context:, **_args)
        aud = context.payload['aud']
        raise JWT::InvalidAudError, "Invalid audience. Expected #{expected_audience}, received #{aud || '<none>'}" if ([*aud] & [*expected_audience]).empty?
      end

      private

      attr_reader :expected_audience
    end
  end
end
