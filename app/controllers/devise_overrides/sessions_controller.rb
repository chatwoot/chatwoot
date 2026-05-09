# rubocop:disable Metrics/ClassLength
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
    rejection_reason = login_rejection_reason(user)
    return handle_login_rejection(user, rejection_reason) if rejection_reason

    params[:email] = user.email if user
    return handle_mfa_required(user) if user&.mfa_enabled?

    # Only proceed with standard authentication if no MFA is required
    super
  end

  def render_create_success
    render partial: 'devise/auth', formats: [:json], locals: { resource: @resource }
    record_successful_employee_login
    record_employee_session
  end

  def destroy
    mark_current_employee_session_signed_out
    super
  end

  private

  def find_user_for_authentication
    return nil unless params[:email].present? && params[:password].present?

    User.from_login_identifier(params[:email])
  end

  def login_rejection_reason(user)
    return :locked if locked_login?(user)
    return :inactive if inactive_employee_login?(user)
    return :invalid_password if invalid_password_login?(user)
    return :unknown_identifier if unknown_login?(user)
  end

  def locked_login?(user)
    user&.locked_for_local_auth?
  end

  def inactive_employee_login?(user)
    user.present? && !active_employee_login?(user)
  end

  def invalid_password_login?(user)
    user.present? && !user.valid_password?(params[:password])
  end

  def unknown_login?(user)
    user.blank? && credentials_present?
  end

  def credentials_present?
    params[:email].present? && params[:password].present?
  end

  def handle_login_rejection(user, rejection_reason)
    return handle_invalid_password(user) if rejection_reason == :invalid_password
    return handle_unknown_login if rejection_reason == :unknown_identifier

    render_login_failure(rejection_reason.to_s, user)
  end

  def handle_invalid_password(user)
    user.record_failed_login! if user.local_employee?
    record_failed_employee_login(user, 'invalid_password')
    render_login_failure('invalid')
  end

  def handle_unknown_login
    record_failed_employee_login(nil, 'unknown_identifier')
    render_login_failure('invalid')
  end

  def render_login_failure(reason, user = nil)
    record_failed_employee_login(user, reason) if user
    render json: {
      success: false,
      message: I18n.t('devise.failure.invalid', authentication_keys: 'login'),
      errors: [I18n.t('devise.failure.invalid', authentication_keys: 'login')]
    }, status: :unauthorized
  end

  def active_employee_login?(user)
    return true unless user.local_employee?

    user.active_employee_account_users.exists?
  end

  def record_failed_employee_login(user, failure_reason)
    EmployeeLoginEvent.create!(
      user: user,
      account: user&.active_employee_account_users&.first&.account,
      success: false,
      login_identifier: params[:email],
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      failure_reason: failure_reason
    )
  end

  def record_successful_employee_login
    return unless @resource&.local_employee?

    @resource.reset_failed_login_attempts!
    @resource.active_employee_account_users.find_each do |account_user|
      EmployeeLoginEvent.create!(
        user: @resource,
        account: account_user.account,
        success: true,
        login_identifier: params[:email],
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
    end
  end

  def record_employee_session
    return unless @resource&.local_employee?

    client_id = employee_auth_client_id
    return if client_id.blank?

    account_user = @resource.active_account_user
    EmployeeSession.find_or_initialize_by(user: @resource, client_id: client_id).tap do |employee_session|
      employee_session.account = account_user&.account
      employee_session.ip_address = request.remote_ip
      employee_session.user_agent = request.user_agent
      employee_session.signed_in_at ||= Time.current
      employee_session.last_seen_at = Time.current
      employee_session.signed_out_at = nil
      employee_session.save!
    end
  end

  def employee_auth_client_id
    @token.try(:client) || @token.try(:[], 'client') || @token.try(:[], :client) || response.headers[DeviseTokenAuth.headers_names[:client]]
  end

  def mark_current_employee_session_signed_out
    return unless current_user&.local_employee?

    client_id = request.headers[DeviseTokenAuth.headers_names[:client]] || request.headers['client']
    current_user.employee_sessions.where(client_id: client_id).open.find_each do |employee_session|
      employee_session.update!(signed_out_at: Time.current)
    end
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
# rubocop:enable Metrics/ClassLength

DeviseOverrides::SessionsController.prepend_mod_with('DeviseOverrides::SessionsController')
