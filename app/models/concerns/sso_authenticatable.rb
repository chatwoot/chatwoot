module SsoAuthenticatable
  extend ActiveSupport::Concern

  def generate_sso_auth_token
    token = SecureRandom.hex(32)
    ::Redis::Alfred.setex(sso_token_key(token), true, 5.minutes)
    token
  end

  def invalidate_sso_auth_token(token)
    ::Redis::Alfred.delete(sso_token_key(token))
  end

  def valid_sso_auth_token?(token)
    ::Redis::Alfred.get(sso_token_key(token)).present?
  end

  private

  def sso_token_key(token)
    format(::Redis::RedisKeys::USER_SSO_AUTH_TOKEN, user_id: id, token: token)
  end
end
