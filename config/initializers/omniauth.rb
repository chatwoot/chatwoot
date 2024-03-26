Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV.fetch('GOOGLE_OAUTH_CLIENT_ID', nil), ENV.fetch('GOOGLE_OAUTH_CLIENT_SECRET', nil), {
    provider_ignores_state: true
  }

  provider :keycloak_openid, ENV.fetch('KEYCLOAK_CLIENT_ID', nil), ENV.fetch('KEYCLOAK_CLIENT_SECRET', nil),
           client_options: { site: 'https://sso.onehash.ai', realm: 'OneHash' },
           name: 'keycloak'
end
