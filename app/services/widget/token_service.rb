class Widget::TokenService
  pattr_initialize [:payload, :token]

  def generate_token
    JWT.encode payload, secret_key, 'HS256'
  end

  def decode_token
    JWT.decode(
      token, secret_key, true, algorithm: 'HS256'
    ).first.symbolize_keys
  rescue StandardError
    {}
  end

  private

  def secret_key
    Rails.application.secrets.secret_key_base
  end
end
