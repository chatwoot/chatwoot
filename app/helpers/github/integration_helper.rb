module Github::IntegrationHelper
  # Generates a signed JWT token for Github integration
  #
  # @param account_id [Integer] The account ID to encode in the token
  # @return [String, nil] The encoded JWT token or nil if client secret is missing
  def generate_github_token(account_id)
    return if github_client_secret.blank?

    JWT.encode(github_token_payload(account_id), github_client_secret, 'HS256')
  rescue StandardError => e
    Rails.logger.error("Failed to generate Github token: #{e.message}")
    nil
  end

  def github_token_payload(account_id)
    {
      sub: account_id,
      iat: Time.current.to_i
    }
  end

  # Verifies and decodes a Github JWT token
  #
  # @param token [String] The JWT token to verify
  # @return [Integer, nil] The account ID from the token or nil if invalid
  def verify_github_token(token)
    return if token.blank? || github_client_secret.blank?

    github_decode_token(token, github_client_secret)
  end

  private

  def github_client_secret
    @github_client_secret ||= GlobalConfigService.load('GITHUB_CLIENT_SECRET', nil)
  end

  def github_decode_token(token, secret)
    JWT.decode(token, secret, true, {
                 algorithm: 'HS256',
                 verify_expiration: true
               }).first['sub']
  rescue StandardError => e
    Rails.logger.error("Unexpected error verifying Github token: #{e.message}")
    nil
  end
end
