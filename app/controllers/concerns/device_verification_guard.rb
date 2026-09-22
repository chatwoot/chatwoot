module DeviceVerificationGuard
  private

  def password_pre_auth_intercepted?
    user = find_user_for_authentication
    return false unless user

    if user.mfa_enabled?
      handle_mfa_required(user)
      return true
    end

    device_verification_intercepted?(user) || enforce_session_limit_for_password_login(user)
  end

  # Enterprise override; must run before session-limit/revocation machinery.
  def device_verification_intercepted?(_user)
    false
  end
end
