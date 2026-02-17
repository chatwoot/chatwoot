class X::TokenService
  include X::OAuthHelper

  pattr_initialize [:channel!]

  def access_token
    return current_access_token if token_valid?

    return refresh_access_token if refresh_token_valid?

    channel.prompt_reauthorization! unless channel.reauthorization_required?
    current_access_token
  end

  def refresh_access_token
    lock_manager = Redis::LockManager.new
    begin
      return current_access_token unless lock_manager.lock(lock_key, 30.seconds)

      channel.reload
      return current_access_token if token_valid?

      result = attempt_refresh_token

      channel.update!(
        bearer_token: result[:access_token],
        refresh_token: result[:refresh_token],
        token_expires_at: result[:expires_at],
        authorization_error_count: 0
      )

      lock_manager.unlock(lock_key)
      channel.bearer_token
    rescue StandardError => e
      lock_manager.unlock(lock_key)
      handle_refresh_error(e)
    end
  end

  private

  def current_access_token
    channel.bearer_token
  end

  def token_expires_at
    channel.token_expires_at
  end

  def refresh_token
    channel.refresh_token
  end

  def refresh_token_expires_at
    channel.refresh_token_expires_at
  end

  def token_valid?
    return false if token_expires_at.blank?

    5.minutes.from_now < token_expires_at
  end

  def refresh_token_valid?
    return false if refresh_token_expires_at.blank?

    Time.current < refresh_token_expires_at
  end

  def lock_key
    format(::Redis::Alfred::X_REFRESH_TOKEN_MUTEX, channel_id: channel.id)
  end

  def attempt_refresh_token
    client = auth_client
    token = OAuth2::AccessToken.from_hash(
      client,
      {
        access_token: channel.bearer_token,
        refresh_token: channel.refresh_token,
        expires_at: channel.token_expires_at.to_i
      }
    )

    new_token = token.refresh!

    {
      access_token: new_token.token,
      refresh_token: new_token.refresh_token,
      expires_at: Time.zone.at(new_token.expires_at)
    }
  end

  def handle_refresh_error(error)
    Rails.logger.error("X token refresh failed for channel #{channel.id}: #{error.message}")
    channel.authorization_error!

    if channel.reauthorization_required?
      AdministratorNotifications::ChannelNotificationsMailer
        .with(account: channel.account)
        .x_disconnect(channel.inbox)
        .deliver_later
    end

    raise error
  end
end
