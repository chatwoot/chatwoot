# frozen_string_literal: true

module Crm
  module Zoho
    class TokenRefresher
      # Scopes necesarios para Zoho CRM
      DEFAULT_SCOPES = [
        'ZohoCRM.org.ALL',
        'ZohoCRM.settings.ALL',
        'ZohoCRM.users.ALL',
        'ZohoCRM.templates.email.READ',
        'ZohoCRM.templates.inventory.READ',
        'ZohoCRM.modules.ALL'
      ].freeze

      DEFAULT_DESK_SCOPES = [
        'Desk.tickets.ALL',
        'Desk.basic.READ'
      ].freeze

      def initialize(hook)
        @hook = hook
        @credentials = hook.credentials
      end

      def refresh!
        response = HTTParty.post(
          "#{ENV.fetch('ZOHO_API_TOKEN_REFRESH', 'https://accounts.zoho.com')}/oauth/v2/token",
          query: build_query_params,
          headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
        )

        unless response.success?
          Rails.logger.error "Zoho token refresh failed: #{response.code} - #{response.body}"
          raise "Token refresh failed: #{response.body}"
        end

        data = response.parsed_response

        if data['error'].present?
          Rails.logger.error "Zoho token refresh returned error: #{data['error']} - #{data['error_description']}"
          raise "Token refresh error: #{data['error']} - #{data['error_description']}"
        end

        unless data['access_token'].present?
          Rails.logger.error "Zoho token refresh returned no access_token: #{data}"
          raise "Token refresh failed: no access_token in response"
        end

        {
          'access_token' => data['access_token'],
          'expires_in' => data['expires_in'],
          'api_domain' => data['api_domain'],
          'token_type' => data['token_type'] || 'Bearer'
        }
      end

      private

      def build_query_params
        {
          client_id: client_id,
          client_secret: client_secret,
          grant_type: 'client_credentials',
          scope: scope_string,
          soid: soid_string
        }
      end

      def soid_string
        values = ["ZohoCRM.#{soid}"]
        values << "Desk.#{desk_soid}" if desk_soid.present?
        values.join(',')
      end

      def scope_string
        scopes = @credentials['scopes'] || DEFAULT_SCOPES
        scopes += DEFAULT_DESK_SCOPES if desk_soid.present?
        scopes.join(',')
      end

      def client_id
        @credentials['client_id'] || @credentials.dig('credentials', 'client_id')
      end

      def client_secret
        @credentials['client_secret'] || @credentials.dig('credentials', 'client_secret')
      end

      def soid
        @credentials['soid'] || @credentials.dig('credentials', 'soid')
      end

      def desk_soid
        @credentials['desk_soid'] || @credentials.dig('credentials', 'desk_soid')
      end
    end
  end
end
