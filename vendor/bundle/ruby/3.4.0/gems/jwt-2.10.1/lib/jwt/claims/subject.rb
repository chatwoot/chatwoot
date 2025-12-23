# frozen_string_literal: true

module JWT
  module Claims
    # The Subject class is responsible for validating the subject claim ('sub') in a JWT token.
    class Subject
      # Initializes a new Subject instance.
      #
      # @param expected_subject [String] the expected subject for the JWT token.
      def initialize(expected_subject:)
        @expected_subject = expected_subject.to_s
      end

      # Verifies the subject claim ('sub') in the JWT token.
      #
      # @param context [Object] the context containing the JWT payload.
      # @param _args [Hash] additional arguments (not used).
      # @raise [JWT::InvalidSubError] if the subject claim is invalid.
      # @return [nil]
      def verify!(context:, **_args)
        sub = context.payload['sub']
        raise(JWT::InvalidSubError, "Invalid subject. Expected #{expected_subject}, received #{sub || '<none>'}") unless sub.to_s == expected_subject
      end

      private

      attr_reader :expected_subject
    end
  end
end
