module Twilio
  module REST
    class ClientTokenManager
      attr_accessor :grant_type, :client_id, :client_secret, :code, :redirect_uri, :audience, :refresh_token, :scope

      def initialize(grant_type, client_id, client_secret, code = nil, redirect_uri = nil, audience = nil,
                     refresh_token = nil, scope = nil)
        raise ArgumentError, 'client_id and client_secret are required' if client_id.nil? || client_secret.nil?

        @grant_type = grant_type
        @client_id = client_id
        @client_secret = client_secret
        @code = code
        @redirect_uri = redirect_uri
        @audience = audience
        @refresh_token = refresh_token
        @scope = scope
      end

      def fetch_access_token
        client = Twilio::REST::Client.new
        token_instance = client.preview_iam.v1.token.create(grant_type: @grant_type,
                                                            client_id: @client_id, client_secret: @client_secret)
        token_instance.access_token
      end
    end
  end
end
