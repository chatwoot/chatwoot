module MfaAuthenticationHelper
  extend ActiveSupport::Concern

  private

  def mfa_verification_request?
    params[:mfa_token].present?
  end

  def mfa_setup_verification_request?
    params[:mfa_setup_token].present?
  end

  def handle_mfa_required(user)
    render json: {
      mfa_required: true,
      mfa_token: Mfa::TokenService.new(user: user).generate_token
    }, status: :partial_content
  end

  def handle_mfa_setup_required(user)
    enrolled_concurrently = false
    # Same lock as verify_and_activate!: a login racing a finished enrolment
    # must not replace the now-active secret with a fresh one.
    user.with_lock do
      if user.mfa_enabled?
        enrolled_concurrently = true
      elsif user.otp_secret.blank?
        user.enable_two_factor!
      end
    end
    return handle_mfa_required(user) if enrolled_concurrently

    render json: {
      mfa_setup_required: true,
      mfa_setup_token: Mfa::SetupTokenService.new(user: user).generate_token,
      provisioning_url: user.mfa_service.two_factor_provisioning_uri,
      secret: user.otp_secret,
      error: I18n.t('errors.mfa.setup_required')
    }, status: :partial_content
  end

  def handle_mfa_setup_verification
    user = Mfa::SetupTokenService.new(token: params[:mfa_setup_token]).verify_token
    return render_mfa_error('errors.mfa.invalid_token', :unauthorized) unless user
    return render_mfa_error('errors.mfa.already_enabled') if user.mfa_enabled?
    return render_mfa_error('errors.mfa.invalid_code') if user.otp_secret.blank? || !user.validate_and_consume_otp!(params[:otp_code])

    @backup_codes = user.mfa_service.verify_and_activate!
    sign_in_mfa_user(user)
  end

  def handle_mfa_verification
    user = Mfa::TokenService.new(token: params[:mfa_token]).verify_token
    return render_mfa_error('errors.mfa.invalid_token', :unauthorized) unless user

    authenticated = Mfa::AuthenticationService.new(
      user: user,
      otp_code: params[:otp_code],
      backup_code: params[:backup_code]
    ).authenticate

    return render_mfa_error('errors.mfa.invalid_code') unless authenticated

    sign_in_mfa_user(user)
  end

  def sign_in_mfa_user(user)
    evict_oldest_session(user) if sessions_limit_reached?(user)
    @resource = user
    @token = @resource.create_token
    @resource.save!

    sign_in(:user, @resource, store: false, bypass: false)
    render_create_success
  end

  def render_mfa_error(message_key, status = :bad_request)
    render json: { error: I18n.t(message_key) }, status: status
  end

  # Password reset and email confirmation must not mint a session for users
  # whose second factor has not been presented: neither enrolled users (the
  # session would bypass their OTP) nor users pending enforced enrolment.
  def mfa_sign_in_required?(user)
    user.mfa_enabled? || user.mfa_enforcement_pending?
  end

  def render_mfa_sign_in_required
    render json: {
      message: I18n.t('messages.mfa_sign_in_required'),
      redirect_url: '/app/login'
    }, status: :ok
  end
end
