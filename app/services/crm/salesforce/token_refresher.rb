# frozen_string_literal: true

module Crm
  module Salesforce
    class TokenRefresher
      OAUTH_TOKEN_URL = 'https://login.salesforce.com/services/oauth2/token'
      SANDBOX_OAUTH_URL = 'https://test.salesforce.com/services/oauth2/token'

      # Salesforce tokens típicamente duran 2 horas (no exponen expires_in en la respuesta)
      DEFAULT_EXPIRES_IN = 7200 # 2 horas en segundos

      def initialize(hook)
        @hook = hook
        @credentials = hook.credentials
      end

      def refresh!
        oauth_url = sandbox? ? SANDBOX_OAUTH_URL : OAUTH_TOKEN_URL

        response = HTTParty.post(
          oauth_url,
          body: build_body_params,
          headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
        )

        unless response.success?
          Rails.logger.error "Salesforce token refresh failed: #{response.code} - #{response.body}"
          raise "Token refresh failed: #{response.body}"
        end

        data = response.parsed_response

        {
          'access_token' => data['access_token'],
          'instance_url' => data['instance_url'],
          'id' => data['id'],
          'token_type' => data['token_type'] || 'Bearer',
          'issued_at' => data['issued_at'],
          'signature' => data['signature'],
          'expires_in' => DEFAULT_EXPIRES_IN # Calculado manualmente
        }
      end

      private

      def build_body_params
        {
          grant_type: 'password',
          client_id: @credentials['client_id'],
          client_secret: @credentials['client_secret'],
          username: @credentials['username'],
          password: @credentials['password']
        }
      end

      def sandbox?
        @credentials['is_sandbox'] == true || @credentials['is_sandbox'] == 'true'
      end
    end
  end
end
