module IntegrationHelper
  # Generates a signed JWT token for Linear integration
  #
  # @param account_id [Integer] The account ID to encode in the token
  # @return [String, nil] The encoded JWT token or nil if client secret is missing
  def generate_linear_token(account_id)
    client_secret = fetch_linear_secret
    return nil unless client_secret

    payload = {
      sub: account_id,
      iat: Time.current.to_i
    }

    JWT.encode(payload, client_secret, 'HS256')
  rescue StandardError => e
    Rails.logger.error("Failed to generate Linear token: #{e.message}")
    nil
  end

  # Verifies and decodes a Linear JWT token
  #
  # @param token [String] The JWT token to verify
  # @return [Integer, nil] The account ID from the token or nil if invalid
  def verify_linear_token(token)
    return nil if token.blank?

    client_secret = fetch_linear_secret
    return nil unless client_secret

    decoded = JWT.decode(token, client_secret, true, {
                           algorithm: 'HS256',
                           verify_expiration: true
                         })
    decoded.first['sub']
  rescue StandardError => e
    Rails.logger.error("Unexpected error verifying Linear token: #{e.message}")
    nil
  end

  private

  def fetch_linear_secret
    ENV.fetch('LINEAR_CLIENT_SECRET', nil)
  end
end
