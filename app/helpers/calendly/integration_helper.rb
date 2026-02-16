module Calendly::IntegrationHelper
  def generate_calendly_token(account_id)
    return if client_secret.blank?

    JWT.encode(calendly_token_payload(account_id), client_secret, 'HS256')
  rescue StandardError => e
    Rails.logger.error("Failed to generate Calendly token: #{e.message}")
    nil
  end

  def verify_calendly_token(token)
    return if token.blank? || client_secret.blank?

    decode_calendly_token(token, client_secret)
  end

  private

  def client_secret
    @client_secret ||= GlobalConfigService.load('CALENDLY_CLIENT_SECRET', nil)
  end

  def calendly_token_payload(account_id)
    {
      sub: account_id,
      iat: Time.current.to_i,
      exp: 10.minutes.from_now.to_i
    }
  end

  def decode_calendly_token(token, secret)
    JWT.decode(token, secret, true, {
                 algorithm: 'HS256',
                 verify_expiration: true
               }).first['sub']
  rescue StandardError => e
    Rails.logger.error("Unexpected error verifying Calendly token: #{e.message}")
    nil
  end
end
