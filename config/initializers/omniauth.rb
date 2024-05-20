Rails.application.config.middleware.use OmniAuth::Builder do
  begin
    client_id = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil)
    client_secret = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_SECRET', nil)
  rescue ActiveRecord::NoDatabaseError
    client_id = ENV.fetch('GOOGLE_OAUTH_CLIENT_ID', nil)
    client_secret = ENV.fetch('GOOGLE_OAUTH_CLIENT_SECRET', nil)
  end

  provider :google_oauth2, client_id, client_secret, { provider_ignores_state: true }
end
