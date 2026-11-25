class Integrations::Linear::AccessTokenService
  include Integrations::Linear::RequestOptions

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
    spent_refresh_token = refresh_token

    response = HTTParty.post(
      TOKEN_URL,
      headers: url_encoded_headers,
      body: {
        grant_type: 'refresh_token',
        refresh_token: spent_refresh_token,
        client_id: client_id,
        client_secret: client_secret
      },
      **LINEAR_REQUEST_OPTIONS
    )

    return fallback_access_token unless response.success?

    persist_tokens(response.parsed_response, spent_refresh_token: spent_refresh_token)
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
      },
      **LINEAR_REQUEST_OPTIONS
    )

    return fallback_access_token unless response.success?

    persist_tokens(response.parsed_response)
    hook.access_token
  rescue StandardError => e
    Rails.logger.error("Linear legacy token migration failed for hook #{hook.id}: #{e.message}")
    fallback_access_token
  end

  # Only the keys this response carries, merged into the row. It used to read `hook.settings` off
  # this object -- loaded before the token call -- and write that copy back, so anything written to
  # the hook while Linear was answering was erased. The `|| current_settings[...]` fallbacks are
  # gone with it: a key the response does not carry is simply not in the merge, which leaves the
  # stored one standing without having to read it first.
  #
  # `swap_json_column!` deliberately leaves this object untouched, so the reload is what lets the
  # callers read the token that is now in the row.
  #
  # `spent_refresh_token` is the precondition of a refresh: the row has to still hold the token this
  # call exchanged. When it does not, an OAuth reconnection landed while Linear was answering, and
  # its tokens are the live ones because an admin just authorised them. Writing over them would undo
  # the reconnection and leave the integration on a token Linear invalidated when it issued the new
  # pair. The legacy migration passes nothing, because it exchanges the access token rather than a
  # rotating refresh token, and there is no earlier value of it to compare against here.
  def persist_tokens(token_data, spent_refresh_token: nil)
    raise ArgumentError, 'Missing access token in Linear token response' if token_data['access_token'].blank?

    result = hook.swap_json_column!(
      :settings,
      expect: spent_refresh_token.present? ? { refresh_token: spent_refresh_token } : {},
      merge: {
        token_type: token_data['token_type'],
        expires_in: token_data['expires_in'],
        expires_on: (expires_on(token_data['expires_in']) if token_data['expires_in'].present?),
        scope: token_data['scope'],
        refresh_token: token_data['refresh_token']
      }.compact,
      attributes: { access_token: token_data['access_token'] }
    )

    if result == :stale
      Rails.logger.warn("[LINEAR] Token refresh for hook #{hook.id} was not stored: the row no longer holds the " \
                        'refresh token this call spent, so a reconnection or another refresh replaced it first')
    end

    hook.reload
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
