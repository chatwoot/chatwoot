# frozen_string_literal: true

module OAuth2
  module Strategy
    # The Authorization Code Strategy
    #
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-15#section-4.1
    class AuthCode < Base
      # The required query parameters for the authorize URL
      #
      # @param [Hash] params additional query parameters
      def authorize_params(params = {})
        params.merge('response_type' => 'code', 'client_id' => @client.id)
      end

      # The authorization URL endpoint of the provider
      #
      # @param [Hash] params additional query parameters for the URL
      def authorize_url(params = {})
        assert_valid_params(params)
        @client.authorize_url(authorize_params.merge(params))
      end

      # Retrieve an access token given the specified validation code.
      #
      # @param [String] code The Authorization Code value
      # @param [Hash] params additional params
      # @param [Hash] opts access_token_opts, @see Client#get_token
      # @note that you must also provide a :redirect_uri with most OAuth 2.0 providers
      def get_token(code, params = {}, opts = {})
        params = {'grant_type' => 'authorization_code', 'code' => code}.merge(@client.redirection_params).merge(params)
        params_dup = params.dup
        params.each_key do |key|
          params_dup[key.to_s] = params_dup.delete(key) if key.is_a?(Symbol)
        end

        @client.get_token(params_dup, opts)
      end

    private

      def assert_valid_params(params)
        raise(ArgumentError, 'client_secret is not allowed in authorize URL query params') if params.key?(:client_secret) || params.key?('client_secret')
      end
    end
  end
end
