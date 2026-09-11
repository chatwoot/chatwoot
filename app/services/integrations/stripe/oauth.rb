class Integrations::Stripe::Oauth
  STATE_TTL = 10.minutes

  def self.configuration_errors(url:, key:)
    return [] if url.blank? && key.blank?

    errors = []
    errors << 'Stripe authorization URL must be an HTTPS Stripe Marketplace URL' unless valid_authorize_url?(URI.parse(url.to_s))
    errors << 'Stripe App secret key must start with sk_test_ or sk_live_' unless key.to_s.match?(/\Ask_(test|live)_[A-Za-z0-9]+\z/)
    errors
  rescue URI::InvalidURIError
    ['Stripe authorization URL is invalid']
  end

  def self.valid_authorize_url?(uri)
    uri.scheme == 'https' && uri.host == 'marketplace.stripe.com' && uri.userinfo.nil?
  end

  def self.configured?
    GlobalConfig.get_value('STRIPE_APP_AUTHORIZE_URL').present? &&
      configuration_errors(url: GlobalConfig.get_value('STRIPE_APP_AUTHORIZE_URL'),
                           key: GlobalConfig.get_value('STRIPE_APP_SECRET_KEY')).empty? && Chatwoot.encryption_configured?
  end

  def self.callback_url
    "#{ENV.fetch('FRONTEND_URL')}/stripe/callback"
  end

  def self.client
    key = GlobalConfig.get_value('STRIPE_APP_SECRET_KEY')
    livemode?

    OAuth2::Client.new(key, '',
                       site: 'https://api.stripe.com', token_url: '/v1/oauth/token', auth_scheme: :basic_auth)
  end

  def self.livemode?
    key = GlobalConfig.get_value('STRIPE_APP_SECRET_KEY')
    raise ArgumentError, 'Invalid Stripe App secret key' unless key&.start_with?('sk_test_', 'sk_live_')

    key.start_with?('sk_live_')
  end

  def self.authorize_url(account:, user:)
    uri = URI(GlobalConfig.get_value('STRIPE_APP_AUTHORIZE_URL'))
    raise ArgumentError, 'Invalid Stripe authorization URL' unless valid_authorize_url?(uri)

    state = SecureRandom.hex(32)
    payload = { account_id: account.id, user_id: user.id, livemode: livemode? }.to_json
    Redis::Alfred.setex("stripe_app:oauth:#{state}", payload, STATE_TTL.to_i)
    query = URI.decode_www_form(uri.query.to_s).to_h.merge('state' => state, 'redirect_uri' => callback_url)
    uri.query = URI.encode_www_form(query)
    uri.to_s
  end

  def self.consume_state(state)
    return unless state.is_a?(String) && state.match?(/\A[0-9a-f]{64}\z/)

    key = "stripe_app:oauth:#{state}"
    payload = Redis::Alfred.get(key)
    return unless payload && Redis::Alfred.delete_if_equals(key, payload)

    JSON.parse(payload)
  end
end
