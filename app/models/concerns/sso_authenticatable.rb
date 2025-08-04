module SsoAuthenticatable
  extend ActiveSupport::Concern

  def generate_sso_auth_token
    return nil unless account&.sso_enabled?

    token = SecureRandom.hex(32)
    expiry_minutes = account.sso_token_expiry.minutes
    ::Redis::Alfred.setex(sso_token_key(token), true, expiry_minutes)
    token
  end

  def invalidate_sso_auth_token(token)
    ::Redis::Alfred.delete(sso_token_key(token))
  end

  def valid_sso_auth_token?(token)
    ::Redis::Alfred.get(sso_token_key(token)).present?
  end

  def generate_sso_link
    return nil unless account&.sso_enabled?

    encoded_email = ERB::Util.url_encode(email)
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/login?email=#{encoded_email}&sso_auth_token=#{generate_sso_auth_token}"
  end

  def generate_sso_link_with_impersonation
    return nil unless account&.sso_enabled?

    "#{generate_sso_link}&impersonation=true"
  end

  def sso_external_login_url
    return nil unless account&.sso_enabled?

    account.sso_login_url
  end

  def sso_external_logout_url
    return nil unless account&.sso_enabled?

    account.sso_logout_url
  end

  private

  def sso_token_key(token)
    format(::Redis::RedisKeys::USER_SSO_AUTH_TOKEN, user_id: id, token: token)
  end
end
