class Sms::BandwidthTokenService
  TOKEN_EXPIRY_BUFFER = 10.seconds
  REQUEST_TIMEOUT = 15

  pattr_initialize [:config!]

  def token(force: false)
    Rails.cache.fetch(cache_key, force: force) do |_key, options|
      access_token = client.client_credentials.get_token
      options.expires_in = access_token.expires_in - TOKEN_EXPIRY_BUFFER
      access_token.token
    end
  rescue OAuth2::Error => e
    Rails.logger.warn("[Bandwidth OAuth] Token request failed: HTTP #{e.response.status}")
    # OAuth errors can include the provider's response. Never expose credentials or tokens.
    raise CustomExceptions::Bandwidth::AuthenticationError.new, cause: nil
  rescue Faraday::Error => e
    Rails.logger.warn("[Bandwidth OAuth] Token request failed: #{e.class.name}")
    raise CustomExceptions::Bandwidth::AuthenticationError.new, cause: nil
  end

  private

  def cache_key
    credentials = config.values_at('account_id', 'client_id', 'client_secret')
    "bandwidth:access_token:#{Digest::SHA256.hexdigest(credentials.to_json)}"
  end

  def client
    OAuth2::Client.new(
      config.fetch('client_id'), config.fetch('client_secret'),
      site: 'https://api.bandwidth.com', token_url: '/api/v1/oauth2/token', auth_scheme: :basic_auth,
      connection_opts: { request: { timeout: REQUEST_TIMEOUT, open_timeout: REQUEST_TIMEOUT } }
    )
  end
end
