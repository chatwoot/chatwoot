module Enterprise::DeviseOverrides::KnownSignInConcern
  KNOWN_COOKIE_TTL = 14.days
  KNOWN_SESSION_WINDOW = 14.days

  private

  def known_sign_in?(user)
    trusted_device?(user) || valid_known_sign_in_cookie?(user) || active_session_from_ip?(user)
  end

  def remember_known_sign_in!(user)
    cookies.encrypted[known_sign_in_cookie_name(user)] = {
      value: {
        'user_id' => user.id,
        'trust_version' => user.device_trust_version,
        'exp' => KNOWN_COOKIE_TTL.from_now.to_i
      },
      expires: KNOWN_COOKIE_TTL.from_now,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax
    }
  end

  def valid_known_sign_in_cookie?(user)
    data = cookies.encrypted[known_sign_in_cookie_name(user)]
    data.present? &&
      data['user_id'] == user.id &&
      data['trust_version'].to_i == user.device_trust_version &&
      data['exp'].to_i > Time.current.to_i
  end

  def active_session_from_ip?(user)
    return false if request.remote_ip.blank?

    user.user_sessions
        .where(ip_address: request.remote_ip)
        .exists?(last_activity_at: KNOWN_SESSION_WINDOW.ago..)
  end

  def known_sign_in_cookie_name(user)
    :"cw_ks_#{user.id}"
  end
end
