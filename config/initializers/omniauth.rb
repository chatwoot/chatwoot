Rails.application.config.middleware.use lambda { |env|
  OmniAuth::Builder.new(env) do
    client_id = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil)
    client_secret = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_SECRET', nil)

    provider :google_oauth2, client_id, client_secret, { provider_ignores_state: true }
  end
}
