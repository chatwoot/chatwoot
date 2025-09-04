class Api::V1::Profile::MfaController < Api::BaseController
  before_action :set_user
  before_action :check_mfa_enabled, only: [:destroy, :backup_codes]
  before_action :check_mfa_disabled, only: [:enable, :verify]
  before_action :validate_otp, only: [:verify, :backup_codes, :destroy]
  before_action :validate_password, only: [:destroy]

  def show; end

  def enable
    @user.enable_two_factor!
    @backup_codes = @user.generate_backup_codes!
  end

  def verify
    @user.update!(otp_required_for_login: true)
  end

  def destroy
    @user.disable_two_factor!
  end

  def backup_codes
    @backup_codes = @user.generate_backup_codes!
  end

  private

  def set_user
    @user = current_user
  end

  def check_mfa_enabled
    render_could_not_create_error(I18n.t('errors.mfa.not_enabled')) unless @user.mfa_enabled?
  end

  def check_mfa_disabled
    render_could_not_create_error(I18n.t('errors.mfa.already_enabled')) if @user.mfa_enabled?
  end

  def validate_otp
    authenticated = Mfa::AuthenticationService.new(
      user: @user,
      otp_code: mfa_params[:otp_code]
    ).authenticate

    return if authenticated

    render_could_not_create_error(I18n.t('errors.mfa.invalid_code'))
  end

  def validate_password
    return if @user.valid_password?(mfa_params[:password])

    render_could_not_create_error(I18n.t('errors.mfa.invalid_credentials'))
  end

  def mfa_params
    params.permit(:otp_code, :password)
  end
end
