class Integrations::Linear::AccessTokenService
  TOKEN_URL = 'https://api.linear.app/oauth/token'.freeze
  MIGRATE_OLD_TOKEN_URL = 'https://api.linear.app/oauth/migrate_old_token'.freeze
  TOKEN_EXPIRY_BUFFER = 1.minute

  pattr_initialize [:hook!]

  def access_token
    return hook.access_token if token_valid?
    return refresh_access_token if refresh_token.present?
    return migrate_legacy_token if migration_applicable?

    hook.access_token
  end

  private

  def refresh_access_token
    response = HTTParty.post(
      TOKEN_URL,
      headers: url_encoded_headers,
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
    Rails.logger.error("Linear token refresh failed for hook #{hook.id}: #{e.message}")
    fallback_access_token
  end

  def migrate_legacy_token
    response = HTTParty.post(
      MIGRATE_OLD_TOKEN_URL,
      headers: url_encoded_headers,
      body: {
        access_token: hook.access_token,
        client_id: client_id,
        client_secret: client_secret
      }
    )

    return fallback_access_token unless response.success?

    persist_tokens(response.parsed_response)
    hook.access_token
  rescue StandardError => e
    Rails.logger.error("Linear legacy token migration failed for hook #{hook.id}: #{e.message}")
    fallback_access_token
  end

  def persist_tokens(token_data)
    raise ArgumentError, 'Missing access token in Linear token response' if token_data['access_token'].blank?

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

  def migration_applicable?
    hook_settings[:token_type].present?
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

  def url_encoded_headers
    { 'Content-Type' => 'application/x-www-form-urlencoded' }
  end

  def client_id
    GlobalConfigService.load('LINEAR_CLIENT_ID', nil)
  end

  def client_secret
    GlobalConfigService.load('LINEAR_CLIENT_SECRET', nil)
  end

  def fallback_access_token
    hook.reload.access_token
  rescue StandardError
    hook.access_token
  end
end
