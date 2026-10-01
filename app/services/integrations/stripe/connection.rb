class Integrations::Stripe::Connection
  class ReauthorizationRequired < StandardError; end

  def initialize(hook)
    @hook = hook
  end

  def store_token!(token)
    @hook.update!(access_token: {
      access_token: token.token,
      refresh_token: token.refresh_token,
      expires_at: 1.hour.from_now.to_i
    }.to_json)
  end

  def api_token
    unless livemode? == Integrations::Stripe::Oauth.livemode?
      raise ReauthorizationRequired, 'Stripe connection environment does not match the configured key'
    end

    credentials = JSON.parse(@hook.access_token)
    return credentials.fetch('access_token') unless expiring?(credentials)

    @hook.with_lock do
      credentials = JSON.parse(@hook.access_token)
      if expiring?(credentials)
        token = OAuth2::AccessToken.new(Integrations::Stripe::Oauth.client, credentials.fetch('access_token'),
                                        refresh_token: credentials.fetch('refresh_token'))
        store_token!(token.refresh!)
        credentials = JSON.parse(@hook.access_token)
      end
      credentials.fetch('access_token')
    end
  end

  def livemode?
    # Connections created before live-mode support are sandbox connections.
    @hook.settings.fetch('livemode', false)
  end

  private

  def expiring?(credentials)
    credentials.fetch('expires_at') <= 1.minute.from_now.to_i
  end
end
