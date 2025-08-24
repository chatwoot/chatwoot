class DeviseOverrides::SessionsController < DeviseTokenAuth::SessionsController
  # Prevent session parameter from being passed
  # Unpermitted parameter: session
  wrap_parameters format: []
  before_action :process_sso_auth_token, only: [:create]

  def new
    redirect_to login_page_url(error: 'access-denied')
  end

  def create
    if params[:mfa_token].present?
      handle_mfa_verification
    elsif params[:sso_auth_token].present? && @resource.present?
      authenticate_resource_with_sso_token
      yield @resource if block_given?
      render_create_success
    else
      super do |resource|
        return handle_mfa_required(resource) if resource&.mfa_enabled?
      end
    end
  end

  def render_create_success
    render partial: 'devise/auth', formats: [:json], locals: { resource: @resource }
  end

  private

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

  def handle_mfa_required(resource)
    mfa_token = generate_mfa_token(resource)

    render json: {
      mfa_required: true,
      mfa_token: mfa_token
    }, status: :partial_content
  end

  def handle_mfa_verification
    user = verify_mfa_token(params[:mfa_token])
    return render_invalid_mfa_token unless user

    otp_code = params[:otp_code]
    backup_code = params[:backup_code]

    if otp_code.present?
      return render_invalid_otp unless user.validate_and_consume_otp!(otp_code)
    elsif backup_code.present?
      return render_invalid_backup_code unless user.invalidate_backup_code!(backup_code)
    else
      return render json: { error: I18n.t('errors.mfa.invalid_code') }, status: :bad_request
    end

    sign_in_mfa_user(user)
  end

  def generate_mfa_token(user)
    payload = { user_id: user.id, exp: 5.minutes.from_now.to_i }
    JWT.encode(payload, Rails.application.secret_key_base)
  end

  def verify_mfa_token(token)
    payload = JWT.decode(token, Rails.application.secret_key_base)[0]
    User.find(payload['user_id'])
  rescue JWT::ExpiredSignature, JWT::DecodeError
    nil
  end

  def sign_in_mfa_user(user)
    @resource = user
    @token = @resource.create_token
    @resource.save!

    sign_in(:user, @resource, store: false, bypass: false)
    render_create_success
  end

  def render_invalid_mfa_token
    render json: { error: I18n.t('errors.mfa.invalid_token', default: 'Invalid or expired MFA token') }, status: :unauthorized
  end

  def render_invalid_otp
    render json: { error: I18n.t('errors.mfa.invalid_code') }, status: :bad_request
  end

  def render_invalid_backup_code
    render json: { error: I18n.t('errors.mfa.invalid_backup_code') }, status: :bad_request
  end
end

DeviseOverrides::SessionsController.prepend_mod_with('DeviseOverrides::SessionsController')
