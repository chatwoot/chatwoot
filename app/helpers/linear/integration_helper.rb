module Linear::IntegrationHelper
  OAUTH_STATE_AUDIENCE = 'linear_oauth'.freeze
  OAUTH_STATE_TTL = 10.minutes

  # Generates a signed JWT token for Linear integration
  #
  # @param account_id [Integer] The account ID to encode in the token
  # @return [String, nil] The encoded JWT token or nil if client secret is missing
  def generate_linear_token(account_id, claims: {})
    return if client_secret.blank?

    JWT.encode(token_payload(account_id).merge(catalog_claims(claims)), client_secret, 'HS256')
  rescue StandardError => e
    Rails.logger.error("Failed to generate Linear token: #{e.message}")
    nil
  end

  def token_payload(account_id)
    {
      sub: account_id,
      iat: Time.current.to_i,
      exp: OAUTH_STATE_TTL.from_now.to_i,
      aud: OAUTH_STATE_AUDIENCE
    }
  end

  # Verifies and decodes a Linear JWT token
  #
  # @param token [String] The JWT token to verify
  # @return [Integer, nil] The account ID from the token or nil if invalid
  def verify_linear_token(token)
    verify_linear_state(token)&.[]('sub')
  end

  def verify_linear_state(token)
    return if token.blank? || client_secret.blank?

    decode_token(token, client_secret)
  end

  private

  def catalog_claims(claims)
    claims.to_h.stringify_keys.slice('installation_id', 'nonce')
  end

  def client_id
    @client_id ||= GlobalConfigService.load('LINEAR_CLIENT_ID', nil)
  end

  def client_secret
    @client_secret ||= GlobalConfigService.load('LINEAR_CLIENT_SECRET', nil)
  end

  def decode_token(token, secret)
    JWT.decode(
      token,
      secret,
      true,
      {
        algorithm: 'HS256',
        verify_expiration: true,
        aud: OAUTH_STATE_AUDIENCE,
        verify_aud: true
      }
    ).first
  rescue StandardError => e
    Rails.logger.error("Unexpected error verifying Linear token: #{e.message}")
    nil
  end
end
