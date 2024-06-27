class BaseRefreshOauthTokenService
  pattr_initialize [:channel!]

  # Additional references: https://gitlab.com/gitlab-org/ruby/gems/gitlab-mail_room/-/blob/master/lib/mail_room/microsoft_graph/connection.rb
  def access_token
    return provider_config[:access_token] unless access_token_expired?

    refreshed_tokens = refresh_tokens
    refreshed_tokens[:access_token]
  end

  def access_token_expired?
    expiry = provider_config[:expires_on]

    return true if expiry.blank?

    # Adding a 5 minute window to expiry check to avoid any race
    # conditions during the fetch operation. This would assure that the
    # tokens are updated when we fetch the emails.
    Time.current.utc >= DateTime.parse(expiry) - 5.minutes
  end

  # Refresh the access tokens using the refresh token
  # Refer: https://github.com/microsoftgraph/msgraph-sample-rubyrailsapp/tree/b4a6869fe4a438cde42b161196484a929f1bee46
  def refresh_tokens
    oauth_strategy = build_oauth_strategy
    token_service = build_token_service(oauth_strategy)

    new_tokens = token_service.refresh!.to_hash.slice(:access_token, :refresh_token, :expires_at)

    update_channel_provider_config(new_tokens)
    channel.reload.provider_config
  end

  def update_channel_provider_config(new_tokens)
    channel.provider_config = {
      access_token: new_tokens[:access_token],
      refresh_token: new_tokens[:refresh_token],
      expires_on: Time.at(new_tokens[:expires_at]).utc.to_s
    }
    channel.save!
  end

  private

  def build_oauth_strategy
    raise NotImplementedError
  end

  def provider_config
    @provider_config ||= channel.provider_config.with_indifferent_access
  end

  # Builds the token service using OAuth2
  def build_token_service(oauth_strategy)
    OAuth2::AccessToken.new(
      oauth_strategy.client,
      provider_config[:access_token],
      refresh_token: provider_config[:refresh_token]
    )
  end
end
