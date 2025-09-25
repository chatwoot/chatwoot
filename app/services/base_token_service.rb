class BaseTokenService
  pattr_initialize [:payload, :token]

  def generate_token
    JWT.encode(token_payload, secret_key, algorithm)
  end

  def decode_token
    JWT.decode(token, secret_key, true, algorithm: algorithm).first.symbolize_keys
  rescue JWT::ExpiredSignature, JWT::DecodeError
    {}
  end

  private

  def token_payload
    payload || {}
  end

  def secret_key
    Rails.application.secret_key_base
  end

  def algorithm
    'HS256'
  end
end
