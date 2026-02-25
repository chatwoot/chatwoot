module Shopify::IntegrationHelper
  REQUIRED_SCOPES = %w[read_customers read_orders read_fulfillments].freeze

  # Generates a signed JWT token for Shopify integration
  #
  # @param account_id [Integer] The account ID to encode in the token
  # @return [String, nil] The encoded JWT token or nil if client secret is missing
  def generate_shopify_token(account_id)
    return if client_secret.blank?

    JWT.encode(token_payload(account_id), client_secret, 'HS256')
  rescue StandardError => e
    Rails.logger.error("Failed to generate Shopify token: #{e.message}")
    nil
  end

  def token_payload(account_id)
    {
      sub: account_id,
      iat: Time.current.to_i
    }
  end

  # Verifies and decodes a Shopify JWT token
  #
  # @param token [String] The JWT token to verify
  # @return [Integer, nil] The account ID from the token or nil if invalid
  def verify_shopify_token(token)
    return if token.blank? || client_secret.blank?

    decode_token(token, client_secret)
  end

  private

  def client_id
    @client_id ||= GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil)
  end

  def client_secret
    @client_secret ||= GlobalConfigService.load('SHOPIFY_CLIENT_SECRET', nil)
  end

  def decode_token(token, secret)
    JWT.decode(
      token,
      secret,
      true,
      {
        algorithm: 'HS256',
        verify_expiration: true
      }
    ).first['sub']
  rescue StandardError => e
    Rails.logger.error("Unexpected error verifying Shopify token: #{e.message}")
    nil
  end
end
