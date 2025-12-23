# frozen_string_literal: true

module OAuth2
  module Strategy
    # The Resource Owner Password Credentials Authorization Strategy
    #
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-15#section-4.3
    class Password < Base
      # Not used for this strategy
      #
      # @raise [NotImplementedError]
      def authorize_url
        raise(NotImplementedError, 'The authorization endpoint is not used in this strategy')
      end

      # Retrieve an access token given the specified End User username and password.
      #
      # @param [String] username the End User username
      # @param [String] password the End User password
      # @param [Hash] params additional params
      def get_token(username, password, params = {}, opts = {})
        params = {'grant_type' => 'password',
                  'username' => username,
                  'password' => password}.merge(params)
        @client.get_token(params, opts)
      end
    end
  end
end
