# Keeps the Pathors OAuth grant usable for API calls made on an account's behalf.
#
# Mirrors Integrations::Linear::AccessTokenService without its legacy-token
# migration branch: the Pathors grant has issued a refresh token since the
# first release of the connect flow, so there is no older shape to migrate.
class Integrations::Pathors::AccessTokenService
  TOKEN_EXPIRY_BUFFER = 1.minute

  pattr_initialize [:hook!]

  def access_token
    return hook.access_token if token_valid?

    refresh!
  end

  # Refreshes regardless of the recorded expiry, for callers that just got a 401
  # back from Pathors and therefore know the stored token is dead early.
  def refresh!
    return fallback_access_token if refresh_token.blank?

    refresh_access_token
  end

  private

  def refresh_access_token
    response = HTTParty.post(
      token_url,
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
      body: {
        grant_type: 'refresh_token',
        refresh_token: refresh_token,
        client_id: client_id,
        client_secret: client_secret
      }
    )

    return fallback_access_token unless response.success?

    persist_tokens(response.parsed_response)
    hook.access_token
  rescue StandardError => e
    Rails.logger.error("Pathors token refresh failed for hook #{hook.id}: #{e.message}")
    fallback_access_token
  end

  # Merged rather than replaced so project_id — written once at consent time and
  # never re-issued by the token endpoint — survives every refresh.
  def persist_tokens(token_data)
    raise ArgumentError, 'Missing access token in Pathors token response' if token_data['access_token'].blank?

    current_settings = hook_settings
    updated_settings = current_settings.merge(
      token_type: token_data['token_type'] || current_settings[:token_type],
      expires_in: token_data['expires_in'] || current_settings[:expires_in],
      expires_on: expires_on(token_data['expires_in']),
      scope: token_data['scope'] || current_settings[:scope],
      refresh_token: token_data['refresh_token'] || current_settings[:refresh_token]
    ).compact

    hook.update!(
      access_token: token_data['access_token'],
      settings: updated_settings
    )
  end

  def token_valid?
    expiry = hook_settings[:expires_on]
    return false if expiry.blank?

    Time.zone.parse(expiry).utc > (Time.current.utc + TOKEN_EXPIRY_BUFFER)
  rescue StandardError
    false
  end

  def refresh_token
    hook_settings[:refresh_token]
  end

  def hook_settings
    hook.settings.to_h.with_indifferent_access
  end

  def expires_on(expires_in)
    return hook_settings[:expires_on] if expires_in.blank?

    (Time.current.utc + expires_in.to_i.seconds).to_s
  end

  def token_url
    "#{GlobalConfigService.load('PATHORS_API_URL', 'https://api.pathors.com')}/oauth/token"
  end

  def client_id
    GlobalConfigService.load('PATHORS_OAUTH_CLIENT_ID', nil)
  end

  def client_secret
    GlobalConfigService.load('PATHORS_OAUTH_CLIENT_SECRET', nil)
  end

  def fallback_access_token
    hook.reload.access_token
  rescue StandardError
    hook.access_token
  end
end
