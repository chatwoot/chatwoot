class Captain::ToolCatalog::SlackOauthState
  AUDIENCE = 'slack_oauth'.freeze
  TTL = 10.minutes

  def initialize(secret:)
    @secret = secret
  end

  def generate(account_id:, installation_id:, nonce:)
    JWT.encode(
      {
        sub: account_id,
        installation_id: installation_id,
        nonce: nonce,
        iat: Time.current.to_i,
        exp: TTL.from_now.to_i,
        aud: AUDIENCE
      },
      secret,
      'HS256'
    )
  end

  def verify(token)
    return if token.blank? || secret.blank?

    JWT.decode(
      token,
      secret,
      true,
      algorithm: 'HS256',
      verify_expiration: true,
      aud: AUDIENCE,
      verify_aud: true
    ).first
  rescue JWT::DecodeError
    nil
  end

  private

  attr_reader :secret
end
