class DeviseOverrides::SessionsController < DeviseTokenAuth::SessionsController
  # Prevent session parameter from being passed
  # Unpermitted parameter: session
  wrap_parameters format: []
  before_action :process_sso_auth_token, only: [:create]

  def new
    redirect_to login_page_url(error: 'access-denied')
  end

  def create
    return handle_mfa_verification if mfa_verification_request?
    return handle_sso_authentication if sso_authentication_request?

    user = find_user_for_authentication
    return handle_mfa_required(user) if user&.mfa_enabled?

    # Only proceed with standard authentication if no MFA is required
    super
  end

  def render_create_success
    render partial: 'devise/auth', formats: [:json], locals: { resource: @resource }
  end

  private

  def find_user_for_authentication
    return nil unless params[:email].present? && params[:password].present?

    normalized_email = params[:email].strip.downcase
    user = User.from_email(normalized_email)
    return nil unless user&.valid_password?(params[:password])
    return nil unless user.active_for_authentication?

    user
  end

  def mfa_verification_request?
    params[:mfa_token].present?
  end

  def sso_authentication_request?
    params[:sso_auth_token].present? && @resource.present?
  end

  def handle_sso_authentication
    authenticate_resource_with_sso_token
    yield @resource if block_given?
    render_create_success
  end

  def login_page_url(error: nil)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)

    "#{frontend_url}/app/login?error=#{error}"
  end

  def authenticate_resource_with_sso_token
    @token = @resource.create_token
    @resource.save!

    sign_in(:user, @resource, store: false, bypass: false)
    # invalidate the token after the user is signed in
    @resource.invalidate_sso_auth_token(params[:sso_auth_token])
  end

  def process_sso_auth_token
    return if params[:email].blank?

    user = User.from_email(params[:email])
    @resource = user if user&.valid_sso_auth_token?(params[:sso_auth_token])
  end

  def handle_mfa_required(user)
    render json: {
      mfa_required: true,
      mfa_token: Mfa::TokenService.new(user: user).generate_token
    }, status: :partial_content
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
    @resource = user
    @token = @resource.create_token
    @resource.save!

    sign_in(:user, @resource, store: false, bypass: false)
    render_create_success
  end

  def render_mfa_error(message_key, status = :bad_request)
    render json: { error: I18n.t(message_key) }, status: status
  end
end

DeviseOverrides::SessionsController.prepend_mod_with('DeviseOverrides::SessionsController')
