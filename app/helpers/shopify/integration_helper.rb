module Shopify::IntegrationHelper
  include OauthStateTokenHelper

  REQUIRED_SCOPES = %w[read_customers read_orders read_fulfillments].freeze

  # Generates a signed JWT token for Shopify integration
  #
  # @param account_id [Integer] The account ID to encode in the token
  # @return [String, nil] The encoded JWT token or nil if client secret is missing
  def generate_shopify_token(account_id)
    return if client_secret.blank?

    generate_oauth_state_token('Shopify', client_secret, token_payload(account_id))
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

    decode_oauth_state_token('Shopify', token, client_secret)&.dig('sub')
  end

  private

  def client_id
    @client_id ||= GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil)
  end

  def client_secret
    @client_secret ||= GlobalConfigService.load('SHOPIFY_CLIENT_SECRET', nil)
  end
end
