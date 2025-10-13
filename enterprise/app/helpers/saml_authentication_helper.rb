module SamlAuthenticationHelper
  def saml_user_attempting_password_auth?(email, sso_auth_token: nil)
    return false if email.blank?

    user = User.from_email(email)
    return false unless user&.provider == 'saml'

    return false if sso_auth_token.present? && user.valid_sso_auth_token?(sso_auth_token)

    true
  end
end
