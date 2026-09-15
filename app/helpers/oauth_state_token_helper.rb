module OauthStateTokenHelper
  extend ActiveSupport::Concern

  def generate_oauth_state_token(provider, secret, payload)
    JWT.encode(payload, secret, 'HS256')
  rescue StandardError => e
    Rails.logger.error("Failed to generate #{provider} token: #{e.message}")
    nil
  end

  def decode_oauth_state_token(provider, token, secret)
    JWT.decode(token, secret, true, { algorithm: 'HS256', verify_expiration: true }).first
  rescue StandardError => e
    Rails.logger.error("Unexpected error verifying #{provider} token: #{e.message}")
    nil
  end
end
