class Integrations::Stripe::Connection
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
    @hook.with_lock do
      credentials = JSON.parse(@hook.access_token)
      if credentials.fetch('expires_at') <= 1.minute.from_now.to_i
        unless livemode? == Integrations::Stripe::Oauth.livemode?
          raise ArgumentError, 'Stripe connection environment does not match the configured key'
        end

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
end
