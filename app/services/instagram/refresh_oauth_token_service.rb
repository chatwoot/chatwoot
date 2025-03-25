# Service to handle Instagram access token refresh logic
# Instagram tokens are valid for 60 days and can be refreshed to extend validity
# This service implements the refresh logic per official Instagram API guidelines
class Instagram::RefreshOauthTokenService
  attr_reader :channel

  def initialize(channel:)
    @channel = channel
  end

  # Returns a valid access token, refreshing it if necessary and eligible
  def access_token
    # Return existing token if valid and not eligible for refresh yet
    return channel[:access_token] if token_valid? && !token_eligible_for_refresh?

    # Only attempt refresh if eligible, otherwise just return current token
    if token_eligible_for_refresh?
      refreshed_token_data = refresh_long_lived_token
      update_channel_tokens(refreshed_token_data)
      channel.reload[:access_token]
    else
      channel[:access_token]
    end
  end

  private

  # Checks if the current token is still valid (not expired)
  def token_valid?
    return false if channel.expires_at.blank?

    # Check if token is still valid
    Time.current < channel.expires_at
  end

  # Determines if a token is eligible for refresh based on Instagram's requirements
  # https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/business-login#refresh-a-long-lived-token

  def token_eligible_for_refresh?
    # Three conditions must be met:
    # 1. Token is still valid
    token_is_valid = Time.current < channel.expires_at

    # 2. Token is at least 24 hours old (based on updated_at)
    token_is_old_enough = channel.updated_at < 24.hours.ago

    # 3. Token is approaching expiry (within 10 days)
    approaching_expiry = channel.expires_at < 10.days.from_now

    token_is_valid && token_is_old_enough && approaching_expiry
  end

  # Makes an API request to refresh the long-lived token
  # @return [Hash] Response data containing new access_token and expires_in values
  # @raise [RuntimeError] If API request fails
  def refresh_long_lived_token
    endpoint = 'https://graph.instagram.com/refresh_access_token'
    params = {
      grant_type: 'ig_refresh_token',
      access_token: channel[:access_token]
    }

    response = HTTParty.get(endpoint, query: params, headers: { 'Accept' => 'application/json' })

    unless response.success?
      Rails.logger.error "Failed to refresh Instagram token: #{response.body}"
      raise "Failed to refresh Instagram token: #{response.body}"
    end

    JSON.parse(response.body)
  end

  def update_channel_tokens(token_data)
    channel.update!(
      access_token: token_data['access_token'],
      expires_at: Time.current + token_data['expires_in'].seconds
    )
  end
end
