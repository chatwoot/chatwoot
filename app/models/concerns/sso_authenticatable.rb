module SsoAuthenticatable
  extend ActiveSupport::Concern

  def generate_sso_auth_token(impersonation: false)
    token = SecureRandom.hex(32)
    ::Redis::Alfred.setex(sso_token_key(token), impersonation ? 'impersonation' : 'normal', 5.minutes)
    token
  end

  def invalidate_sso_auth_token(token)
    ::Redis::Alfred.delete(sso_token_key(token))
  end

  def valid_sso_auth_token?(token)
    ::Redis::Alfred.get(sso_token_key(token)).present?
  end

  def generate_sso_link
    encoded_email = ERB::Util.url_encode(email)
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/login?email=#{encoded_email}&sso_auth_token=#{generate_sso_auth_token}"
  end

  def sso_auth_token_impersonation?(token)
    ::Redis::Alfred.get(sso_token_key(token)) == 'impersonation'
  end

  def generate_sso_link_with_impersonation
    encoded_email = ERB::Util.url_encode(email)
    "#{ENV.fetch('FRONTEND_URL',
                 nil)}/app/login?email=#{encoded_email}&sso_auth_token=#{generate_sso_auth_token(impersonation: true)}&impersonation=true"
  end

  private

  def sso_token_key(token)
    format(::Redis::RedisKeys::USER_SSO_AUTH_TOKEN, user_id: id, token: token)
  end
end
