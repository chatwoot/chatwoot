# frozen_string_literal: true

module OAuth2
  module Strategy
    # The Implicit Strategy
    #
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-26#section-4.2
    class Implicit < Base
      # The required query parameters for the authorize URL
      #
      # @param [Hash] params additional query parameters
      def authorize_params(params = {})
        params.merge('response_type' => 'token', 'client_id' => @client.id)
      end

      # The authorization URL endpoint of the provider
      #
      # @param [Hash] params additional query parameters for the URL
      def authorize_url(params = {})
        assert_valid_params(params)
        @client.authorize_url(authorize_params.merge(params))
      end

      # Not used for this strategy
      #
      # @raise [NotImplementedError]
      def get_token(*)
        raise(NotImplementedError, 'The token is accessed differently in this strategy')
      end

    private

      def assert_valid_params(params)
        raise(ArgumentError, 'client_secret is not allowed in authorize URL query params') if params.key?(:client_secret) || params.key?('client_secret')
      end
    end
  end
end
