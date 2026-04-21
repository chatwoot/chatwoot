class Api::V1::Profile::MfaController < Api::BaseController
  before_action :check_mfa_feature_available
  before_action :check_mfa_enabled, only: [:destroy, :backup_codes]
  before_action :check_mfa_disabled, only: [:create, :verify]
  before_action :validate_otp, only: [:verify, :backup_codes, :destroy]
  before_action :validate_password, only: [:destroy]

  def show; end

  def create
    mfa_service.enable_two_factor!
  end

  def verify
    @backup_codes = mfa_service.verify_and_activate!
  end

  def destroy
    mfa_service.disable_two_factor!
  end

  def backup_codes
    @backup_codes = mfa_service.generate_backup_codes!
  end

  private

  def mfa_service
    @mfa_service ||= Mfa::ManagementService.new(user: current_user)
  end

  def check_mfa_enabled
    render_could_not_create_error(I18n.t('errors.mfa.not_enabled')) unless current_user.mfa_enabled?
  end

  def check_mfa_feature_available
    return if Chatwoot.mfa_enabled?

    render json: {
      error: I18n.t('errors.mfa.feature_unavailable')
    }, status: :forbidden
  end

  def check_mfa_disabled
    render_could_not_create_error(I18n.t('errors.mfa.already_enabled')) if current_user.mfa_enabled?
  end

  def validate_otp
    authenticated = Mfa::AuthenticationService.new(
      user: current_user,
      otp_code: mfa_params[:otp_code]
    ).authenticate

    return if authenticated

    render_could_not_create_error(I18n.t('errors.mfa.invalid_code'))
  end

  def validate_password
    return if current_user.valid_password?(mfa_params[:password])

    render_could_not_create_error(I18n.t('errors.mfa.invalid_credentials'))
  end

  def mfa_params
    params.permit(:otp_code, :password)
  end
end
