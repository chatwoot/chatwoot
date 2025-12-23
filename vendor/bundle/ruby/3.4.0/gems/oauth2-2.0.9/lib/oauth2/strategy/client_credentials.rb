# frozen_string_literal: true

module OAuth2
  module Strategy
    # The Client Credentials Strategy
    #
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-15#section-4.4
    class ClientCredentials < Base
      # Not used for this strategy
      #
      # @raise [NotImplementedError]
      def authorize_url
        raise(NotImplementedError, 'The authorization endpoint is not used in this strategy')
      end

      # Retrieve an access token given the specified client.
      #
      # @param [Hash] params additional params
      # @param [Hash] opts options
      def get_token(params = {}, opts = {})
        params = params.merge('grant_type' => 'client_credentials')
        @client.get_token(params, opts)
      end
    end
  end
end
