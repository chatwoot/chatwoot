# Service to handle TikTok channel access token refresh logic
# TikTok access tokens are valid for 1 day and can be refreshed to extend validity
class Tiktok::TokenService
  pattr_initialize [:channel!]

  # Returns a valid access token, refreshing it if necessary and eligible
  def access_token
    return current_access_token if token_valid?

    return refresh_access_token if refresh_token_valid?

    channel.prompt_reauthorization! unless channel.reauthorization_required?
    return current_access_token
  end

  private

  def current_access_token
    channel.access_token
  end

  def expires_at
    channel.expires_at
  end

  def refresh_token
    channel.refresh_token
  end

  def refresh_token_expires_at
    channel.refresh_token_expires_at
  end

  # Checks if the current token is still valid (not expired)
  def token_valid?
    5.minutes.from_now < expires_at
  end

  def refresh_token_valid?
    Time.current < refresh_token_expires_at
  end

  # Makes an API request to refresh the access token
  # @return [String] Refreshed access token
  def refresh_access_token
    lock_manager = Redis::LockManager.new
    begin
      # Could not acquire lock, another process is likely refreshing the token
      # return the current token as it should still be valid for the next 30 minutes
      return current_access_token unless lock_manager.lock(lock_key, 30.seconds)

      result = attempt_refresh_token
      new_token = result[:access_token]

      channel.update!(
        access_token: new_token,
        refresh_token: result[:refresh_token],
        expires_at: result[:expires_at],
        refresh_token_expires_at: result[:refresh_token_expires_at]
      )

      lock_manager.unlock(lock_key)
      new_token
    rescue StandardError => e
      lock_manager.unlock(lock_key)
      raise e
    end
  end

  def lock_key
    format(::Redis::Alfred::TIKTOK_REFRESH_TOKEN_MUTEX, channel_id: channel.id)
  end

  def attempt_refresh_token
    Tiktok::AuthClient.renew_short_term_access_token(refresh_token)
  end
end
