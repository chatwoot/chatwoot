class Api::V1::Profile::PasskeysController < Api::BaseController
  # A stolen API token or hijacked session must not be able to plant a
  # passkey, so registration needs an interactive session, the password and,
  # when enabled, the second factor the passkey will stand in for.
  before_action :ensure_interactive_session
  before_action :ensure_passkeys_enabled
  before_action :ensure_passkey_eligible, only: [:registration_options, :create]
  before_action :ensure_below_passkey_limit, only: [:registration_options, :create]
  before_action :validate_password, only: [:registration_options]
  before_action :validate_second_factor, only: [:registration_options]

  def index
    @passkeys = current_user.passkeys.order(:created_at)
  end

  def registration_options
    render json: registration_service.options
  end

  def create
    @passkey = registration_service.register(credential: credential_params, name: passkey_name)
    render_could_not_create_error(I18n.t('errors.passkeys.registration_failed')) unless @passkey
  end

  def destroy
    current_user.passkeys.find(params[:id]).destroy!
    head :ok
  end

  private

  def registration_service
    @registration_service ||= Passkeys::RegistrationService.new(user: current_user)
  end

  def ensure_interactive_session
    return unless authenticate_by_access_token?

    render json: { error: I18n.t('errors.passkeys.interactive_session_required') }, status: :forbidden
  end

  def ensure_passkeys_enabled
    head :not_found unless Passkeys.enabled?
  end

  def ensure_passkey_eligible
    return unless current_user.provider == 'saml'

    render json: { error: I18n.t('errors.passkeys.not_available_for_sso') }, status: :forbidden
  end

  def ensure_below_passkey_limit
    return if current_user.passkeys.count < Passkey::MAX_PER_USER

    render_could_not_create_error(I18n.t('errors.passkeys.limit_reached', limit: Passkey::MAX_PER_USER))
  end

  def validate_password
    return if current_user.valid_password?(params[:password].to_s)

    render_could_not_create_error(I18n.t('errors.passkeys.invalid_password'))
  end

  def validate_second_factor
    return unless current_user.mfa_enabled?

    authenticated = Mfa::AuthenticationService.new(
      user: current_user, otp_code: params[:otp_code].to_s.presence, backup_code: params[:backup_code].to_s.presence
    ).authenticate
    render_could_not_create_error(I18n.t('errors.mfa.invalid_code')) unless authenticated
  end

  def credential_params
    credential = params[:credential]
    credential.respond_to?(:to_unsafe_h) ? credential.to_unsafe_h : {}
  end

  def passkey_name
    params[:name].to_s.strip.first(64).presence || I18n.t('passkeys.default_name')
  end
end
