module SsoAuthenticatable
  extend ActiveSupport::Concern

  def generate_sso_auth_token(impersonated_by: nil)
    token = SecureRandom.hex(32)
    value = impersonated_by ? "impersonation:#{impersonated_by.id}" : 'normal'
    ::Redis::Alfred.setex(sso_token_key(token), value, 5.minutes)
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
    ::Redis::Alfred.get(sso_token_key(token)).to_s.start_with?('impersonation')
  end

  def sso_auth_token_impersonator_id(token)
    value = ::Redis::Alfred.get(sso_token_key(token)).to_s
    value.delete_prefix('impersonation:').to_i if value.start_with?('impersonation:')
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
end
