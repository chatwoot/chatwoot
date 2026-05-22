class AppStoreConnect::TokenService
  TOKEN_TTL = 19.minutes
  EXPIRY_BUFFER = 1.minute

  pattr_initialize [:channel!]

  def token
    cached_token || generate_token
  end

  private

  def cached_token
    Rails.cache.read(cache_key)
  end

  def generate_token
    token = JWT.encode(payload, private_key, 'ES256', headers)
    Rails.cache.write(cache_key, token, expires_in: TOKEN_TTL - EXPIRY_BUFFER)
    token
  end

  def payload
    now = Time.current.to_i
    {
      iss: channel.issuer_id,
      iat: now,
      exp: now + TOKEN_TTL.to_i,
      aud: 'appstoreconnect-v1'
    }
  end

  def headers
    {
      kid: channel.key_id,
      typ: 'JWT'
    }
  end

  def private_key
    OpenSSL::PKey.read(channel.private_key.to_s.gsub('\\n', "\n"))
  end

  def cache_key
    "app_store_connect_token:#{channel.id}:#{channel.updated_at.to_i}"
  end
end
