# frozen_string_literal: true

class SuperAdmin::Devise::SessionsController < Devise::SessionsController
  MFA_CHALLENGE_EXPIRY = 5.minutes
  MFA_MAX_FAILED_ATTEMPTS = 5
  MFA_FAILED_ATTEMPTS_WINDOW = 15.minutes

  def new
    @mfa_challenge = pending_mfa_super_admin.present?
    self.resource = resource_class.new(sign_in_params)
  end

  def create
    return verify_mfa_code if params.dig(:super_admin, :otp_code).present?

    redirect_to(super_admin_session_path, flash: { error: @error_message }) && return unless valid_credentials?
    return start_mfa_challenge if @super_admin.mfa_enabled?

    complete_sign_in(@super_admin)
  end

  def destroy
    sign_out
    flash.discard
    redirect_to '/'
  end

  private

  def valid_credentials?
    @super_admin = SuperAdmin.find_by!(email: params[:super_admin][:email])
    raise StandardError, 'Invalid Password' unless @super_admin.valid_password?(params[:super_admin][:password])

    true
  rescue StandardError => e
    Rails.logger.error e.message
    @error_message = 'Invalid credentials. Please try again.'
    false
  end

  def start_mfa_challenge
    session[:super_admin_mfa] = { 'id' => @super_admin.id, 'expires_at' => MFA_CHALLENGE_EXPIRY.from_now.to_i }
    redirect_to super_admin_session_path
  end

  def verify_mfa_code
    super_admin = pending_mfa_super_admin
    return redirect_to(super_admin_session_path, flash: { error: I18n.t('super_admin.login.mfa_expired') }) unless super_admin
    return end_mfa_challenge if mfa_attempts_exhausted?(super_admin)
    return reject_mfa_code(super_admin) unless valid_mfa_code?(super_admin)

    Redis::Alfred.delete(mfa_failed_attempts_key(super_admin))
    session.delete(:super_admin_mfa)
    complete_sign_in(super_admin)
  end

  def reject_mfa_code(super_admin)
    key = mfa_failed_attempts_key(super_admin)
    Redis::Alfred.expire(key, MFA_FAILED_ATTEMPTS_WINDOW) if Redis::Alfred.incr(key) == 1
    redirect_to(super_admin_session_path, flash: { error: I18n.t('super_admin.login.mfa_invalid') })
  end

  def end_mfa_challenge
    session.delete(:super_admin_mfa)
    redirect_to(super_admin_session_path, flash: { error: I18n.t('super_admin.login.mfa_attempts_exhausted') })
  end

  def mfa_attempts_exhausted?(super_admin)
    Redis::Alfred.get(mfa_failed_attempts_key(super_admin)).to_i >= MFA_MAX_FAILED_ATTEMPTS
  end

  def mfa_failed_attempts_key(super_admin)
    format(Redis::RedisKeys::SUPER_ADMIN_MFA_FAILED_ATTEMPTS, user_id: super_admin.id)
  end

  def valid_mfa_code?(super_admin)
    code = params[:super_admin][:otp_code].to_s.strip
    otp_code, backup_code = code.match?(/\A\d{6}\z/) ? [code, nil] : [nil, code.upcase]

    Mfa::AuthenticationService.new(user: super_admin, otp_code: otp_code, backup_code: backup_code).authenticate
  end

  def pending_mfa_super_admin
    challenge = session[:super_admin_mfa]
    return if challenge.blank?

    if challenge['expires_at'].to_i < Time.current.to_i
      session.delete(:super_admin_mfa)
      return
    end

    SuperAdmin.find_by(id: challenge['id'])
  end

  def complete_sign_in(super_admin)
    sign_in(:super_admin, super_admin)
    flash.discard
    redirect_to super_admin_root_path
  end
end
