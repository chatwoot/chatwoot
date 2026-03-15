# OmniAuth configuration
# Sets the full host URL for callbacks and proper redirect handling
OmniAuth.config.full_host = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV.fetch('GOOGLE_OAUTH_CLIENT_ID', nil), ENV.fetch('GOOGLE_OAUTH_CLIENT_SECRET', nil), {
    provider_ignores_state: true
  }

  if ENV['HUB_OAUTH_CLIENT_ID'].present?
    provider :igarahub,
             ENV.fetch('HUB_OAUTH_CLIENT_ID', nil),
             ENV.fetch('HUB_OAUTH_CLIENT_SECRET', nil),
             client_options: {
               site: ENV.fetch('HUB_URL', 'http://localhost:8001'),
               authorize_url: '/oauth/authorize',
               token_url: '/oauth/token'
             }
  end
end
