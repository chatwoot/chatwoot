module SsoAuthenticatable
  extend ActiveSupport::Concern

  def generate_sso_auth_token(impersonated_by: nil)
    token = SecureRandom.hex(32)
    ::Redis::Alfred.setex(sso_token_key(token), impersonated_by ? 'impersonation' : 'normal', 5.minutes)
    ::Redis::Alfred.setex(sso_impersonator_key(token), impersonated_by.id, 5.minutes) if impersonated_by
    token
  end

  def invalidate_sso_auth_token(token)
    ::Redis::Alfred.delete(sso_token_key(token))
    ::Redis::Alfred.delete(sso_impersonator_key(token))
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

  def sso_auth_token_impersonator_id(token)
    ::Redis::Alfred.get(sso_impersonator_key(token))&.to_i
  end

  def generate_sso_link_with_impersonation(impersonated_by)
    encoded_email = ERB::Util.url_encode(email)
    sso_auth_token = generate_sso_auth_token(impersonated_by: impersonated_by)
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/login?email=#{encoded_email}&sso_auth_token=#{sso_auth_token}&impersonation=true"
  end

  private

  def sso_token_key(token)
    format(::Redis::RedisKeys::USER_SSO_AUTH_TOKEN, user_id: id, token: token)
  end

  def sso_impersonator_key(token)
    format(::Redis::RedisKeys::USER_SSO_IMPERSONATOR, user_id: id, token: token)
  end
end
