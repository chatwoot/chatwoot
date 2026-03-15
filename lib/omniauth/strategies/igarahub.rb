require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Igarahub < OmniAuth::Strategies::OAuth2
      option :name, 'igarahub'

      option :client_options, {
        site: ENV.fetch('HUB_URL', 'http://localhost:8001'),
        authorize_url: '/oauth/authorize',
        token_url: '/oauth/token'
      }

      option :authorize_params, {
        scope: 'openid profile email'
      }

      uid { raw_info['user_id'] }

      info do
        {
          name: raw_info['name'],
          email: raw_info['email'],
          client_slug: raw_info['client_slug'],
          organization_id: raw_info['organization_id'],
          roles: raw_info['roles']
        }
      end

      extra do
        { raw_info: raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get('/auth/userinfo').parsed
      end

      def callback_url
        full_host + callback_path
      end
    end
  end
end
