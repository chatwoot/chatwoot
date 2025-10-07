# Manages OAuth2 token lifecycle for Linear integration
# Handles automatic token refresh and migration from long-lived to short-lived tokens
class Linear::TokenRefreshService
  TOKEN_URL = 'https://api.linear.app/oauth/token'.freeze
  MIGRATE_TOKEN_URL = 'https://api.linear.app/oauth/migrate_old_token'.freeze

  def initialize(hook)
    @hook = hook
  end

  # Returns a valid access token, handling refresh/migration automatically
  # This is the main entry point - call this whenever you need a valid token
  # @return [String] Valid OAuth access token
  def token
    return @hook.access_token unless @hook

    # For existing accounts without refresh token, attempt migration first
    # This migrates long-lived tokens to the new refresh token system, https://linear.app/developers/oauth-2-0-authentication#migrate-to-using-refresh-tokens
    migrate_old_token unless refresh_token?

    refresh_access_token if token_eligible_for_refresh?

    @hook.access_token
  end

  def refresh_access_token
    return false unless @hook&.settings&.dig('refresh_token')

    response = HTTParty.post(
      TOKEN_URL,
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
      body: {
        grant_type: 'refresh_token',
        refresh_token: @hook.settings['refresh_token'],
        client_id: GlobalConfigService.load('LINEAR_CLIENT_ID', nil),
        client_secret: GlobalConfigService.load('LINEAR_CLIENT_SECRET', nil)
      }
    )

    if response.success?
      update_tokens(response.parsed_response)
      true
    else
      Rails.logger.error("Linear token refresh failed: #{response.parsed_response}")
      false
    end
  end

  def migrate_old_token
    return false unless @hook

    response = HTTParty.post(
      MIGRATE_TOKEN_URL,
      headers: {
        'Authorization' => "Bearer #{@hook.access_token}",
        'Content-Type' => 'application/json'
      }
    )

    if response.success?
      update_tokens(response.parsed_response)
      true
    else
      Rails.logger.error("Linear token migration failed: #{response.parsed_response}")
      false
    end
  end

  def token_expired?
    return false unless @hook&.settings&.dig('expires_at')

    Time.zone.parse(@hook.settings['expires_at']) <= Time.current
  end

  def token_eligible_for_refresh?
    return false unless @hook&.settings&.dig('expires_at')
    return false unless @hook&.settings&.dig('refresh_token')

    expires_at = Time.zone.parse(@hook.settings['expires_at'])

    # Three conditions must be met for proactive refresh:
    # 1. Token is still valid (not expired yet)
    token_is_valid = Time.current < expires_at

    # 2. Token is at least 24 hours old (prevents excessive refresh attempts)
    token_is_old_enough = @hook.updated_at.present? && Time.current - @hook.updated_at >= 24.hours

    # 3. Token is approaching expiry (within 10 days)
    # This gives enough buffer to handle refresh failures
    approaching_expiry = expires_at < 10.days.from_now

    token_is_valid && token_is_old_enough && approaching_expiry
  end

  def refresh_token?
    @hook&.settings&.dig('refresh_token').present?
  end

  private

  def update_tokens(response_data)
    return unless @hook

    @hook.update!(
      access_token: response_data['access_token'],
      settings: @hook.settings.merge(
        token_type: response_data['token_type'],
        expires_in: response_data['expires_in'],
        scope: response_data['scope'],
        refresh_token: response_data['refresh_token'] || @hook.settings['refresh_token'],
        expires_at: calculate_expires_at(response_data['expires_in'])
      ).compact
    )
  end

  def calculate_expires_at(expires_in)
    return nil unless expires_in

    (Time.current + expires_in.to_i.seconds).iso8601
  end
end
