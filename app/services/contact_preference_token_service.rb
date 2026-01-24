# CommMate: Token service for contact preference management
# Generates secure JWT tokens for public preference pages
class ContactPreferenceTokenService < BaseTokenService
  EXPIRY_DAYS = 30

  def generate_token
    JWT.encode(token_payload, secret_key, algorithm)
  end

  def decode_token
    decoded = JWT.decode(token, secret_key, true, algorithm: algorithm).first.symbolize_keys
    # Validate required fields are present
    raise JWT::DecodeError, 'Invalid token payload' unless decoded[:contact_id] && decoded[:account_id]

    decoded
  rescue JWT::ExpiredSignature
    { error: :expired }
  rescue JWT::DecodeError
    { error: :invalid }
  end

  def self.generate_for_contact(contact)
    new(payload: { contact_id: contact.id, account_id: contact.account_id }).generate_token
  end

  def self.generate_preference_url(contact)
    token = generate_for_contact(contact)
    base_url = ENV.fetch('FRONTEND_URL', nil) || GlobalConfigService.load('FRONTEND_URL', nil) || 'http://localhost:3000'
    "#{base_url}/preferences/#{token}"
  end

  private

  def token_payload
    {
      contact_id: payload[:contact_id],
      account_id: payload[:account_id],
      exp: Time.zone.now.to_i + EXPIRY_DAYS.days.to_i,
      iat: Time.zone.now.to_i
    }
  end
end
