class Widget::TokenService < BaseTokenService
  DEFAULT_EXPIRY_DAYS = 180

  def self.payload_for(contact_inbox)
    {
      source_id: contact_inbox.source_id,
      inbox_id: contact_inbox.inbox_id,
      token_version: contact_inbox.widget_token_version.to_i
    }
  end

  def generate_token
    JWT.encode(token_payload, secret_key, algorithm)
  end

  private

  def token_payload
    (payload || {}).merge(exp: exp, iat: iat)
  end

  def iat
    Time.zone.now.to_i
  end

  def exp
    iat + expire_in.days.to_i
  end

  def expire_in
    # Value is stored in days, defaulting to 6 months (180 days)
    token_expiry_value = InstallationConfig.find_by(name: 'WIDGET_TOKEN_EXPIRY')&.value
    (token_expiry_value.presence || DEFAULT_EXPIRY_DAYS).to_i
  end
end
