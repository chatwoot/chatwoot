module Enterprise::DeviseOverrides::DeviceVerificationConcern
  DEVICE_COOKIE_TTL = 30.days

  def device_verification_intercepted?(user)
    return false unless DeviceVerification.enabled?
    return false if trusted_device?(user)

    token = DeviceVerification::ChallengeService.new(user: user, request_meta: device_request_meta).issue!
    if token
      render json: { mfa_required: true, verification_channel: 'email', mfa_token: token }, status: :partial_content
    else
      render json: { error: I18n.t('errors.device_verification.rate_limited') }, status: :too_many_requests
    end
    true
  end

  def handle_mfa_verification
    claims = DeviceVerification::TokenService.new(token: params[:mfa_token]).decode_claims
    return super if claims.blank?

    return render_device_verification_error(:code_field_required) if params[:otp_code].blank? && params[:backup_code].present?

    result = DeviceVerification::ChallengeService.redeem(token: params[:mfa_token], code: params[:otp_code])
    return render_device_verification_error(result[:error]) if result[:error]

    complete_device_verification(result[:user])
  end

  private

  def complete_device_verification(user)
    remember_device!(user) if remember_this_device?
    # Sign in before notifying: the code is already consumed, so a mailer failure
    # must not block authentication and strand the user with a spent code.
    sign_in_mfa_user(user)
    notify_new_device(user)
  end

  # Default to trusting the device: an absent param covers shipped mobile clients
  # that do not send it and matches the default-checked box on the web screen. Only
  # an explicit "false" (user unchecked it) skips the trusted-device cookie.
  def remember_this_device?
    return true if params[:remember_device].nil?

    ActiveModel::Type::Boolean.new.cast(params[:remember_device])
  end

  def notify_new_device(user)
    Enterprise::DeviceVerificationMailer.new_device(user, device_request_meta).deliver_later(queue: 'critical')
  rescue StandardError => e
    Rails.logger.warn "Device verification new-device email could not be enqueued: #{e.message}"
  end

  def render_device_verification_error(error)
    status = error == :invalid_token ? :unauthorized : :bad_request
    render json: { error: I18n.t("errors.device_verification.#{error}") }, status: status
  end

  def trusted_device?(user)
    data = cookies.encrypted[device_cookie_name(user)]
    data.present? && data['trust_version'].to_i == user.device_trust_version
  end

  def remember_device!(user)
    cookies.encrypted[device_cookie_name(user)] = {
      value: { 'device_id' => SecureRandom.uuid, 'trust_version' => user.device_trust_version },
      expires: DEVICE_COOKIE_TTL.from_now,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax
    }
  end

  def device_cookie_name(user)
    :"cw_dv_#{user.id}"
  end

  def device_request_meta
    info = RequestDeviceInfo.new(request)
    { ip: request.remote_ip, browser_name: info.browser_name, platform_name: info.platform_label }
  end
end
