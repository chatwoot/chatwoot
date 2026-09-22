class DeviseOverrides::SessionsController < DeviseTokenAuth::SessionsController
  include DeviceVerificationGuard
  include SignInSessionLimitable

  # Prevent session parameter from being passed
  # Unpermitted parameter: session
  wrap_parameters format: []
  # DTA's params_for_resource copies these headers into params during super.
  # Mirror that up front so every pre-authentication check in create sees the
  # same credentials a header-only request would authenticate with.
  before_action :merge_credential_headers, only: [:create]
  before_action :process_sso_auth_token, only: [:create]

  def new
    redirect_to login_page_url(error: 'access-denied')
  end

  def create
    return handle_mfa_verification if mfa_verification_request?
    return handle_sso_authentication if sso_authentication_request?
    return render_sign_in_blocked if abuse_tracker.blocked?
    return if password_pre_auth_intercepted?

    # Only proceed with standard authentication if no MFA is required
    super
  end

  def render_create_success
    track_user_session unless @impersonation
    render partial: 'devise/auth', formats: [:json], locals: { resource: @resource }
  end

  private

  def render_create_error_not_confirmed
    render_error(
      :unauthorized,
      I18n.t('devise_token_auth.sessions.not_confirmed', email: @resource.email),
      error_code: 'user_not_confirmed'
    )
  end

  def render_create_error_account_locked
    track_failed_sign_in
    render_error(
      :unauthorized,
      I18n.t('devise.failure.locked'),
      error_code: 'account_locked'
    )
  end

  def render_create_error_bad_credentials
    track_failed_sign_in
    return render_create_error_account_locked if @resource&.access_locked?

    super
  end

  def render_sign_in_blocked
    render_error(:too_many_requests, I18n.t('errors.sign_in.blocked'), error_code: 'sign_in_blocked')
  end

  def abuse_tracker
    @abuse_tracker ||= Auth::SignInAbuseTracker.new(ip: request.remote_ip)
  end

  def track_failed_sign_in
    return if @failed_sign_in_tracked

    @failed_sign_in_tracked = true
    abuse_tracker.record_failure(params[:email])
  end

  def merge_credential_headers
    params[:email] ||= request.headers['email'] unless request.headers['email'].nil?
    params[:password] ||= request.headers['password'] unless request.headers['password'].nil?
  end

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
    return if !@impersonation && enforce_session_limit_for_password_login(@resource)

    authenticate_resource_with_sso_token
    yield @resource if block_given?
    render_create_success
  end

  def login_page_url(error: nil)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)

    "#{frontend_url}/app/login?error=#{error}"
  end

  def authenticate_resource_with_sso_token
    # SSO proves identity via the IdP, so clear any lock (as a successful password reset does).
    @resource.unlock_access! if @resource.locked_at.present?
    # DTA evicts the earliest-expiring token after save when at max_number_of_devices.
    # The short-lived impersonation token would always be that one, so pre-evict to make room.
    make_room_for_impersonation_token if @impersonation
    @token = @resource.create_token(lifespan: @impersonation ? 2.days.to_i : nil)
    @resource.save!

    sign_in(:user, @resource, store: false, bypass: false)
    # invalidate the token after the user is signed in
    @resource.invalidate_sso_auth_token(params[:sso_auth_token])
  end

  def make_room_for_impersonation_token
    return if @resource.tokens.size < DeviseTokenAuth.max_number_of_devices

    oldest_client_id = @resource.tokens.min_by { |_, v| v['expiry'].to_i }&.first
    @resource.tokens.delete(oldest_client_id) if oldest_client_id
  end

  def process_sso_auth_token
    return if params[:email].blank?

    user = User.from_email(params[:email])
    return unless user&.valid_sso_auth_token?(params[:sso_auth_token])

    @resource = user
    @impersonation = user.sso_auth_token_impersonation?(params[:sso_auth_token])
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
    return render_create_error_account_locked if user.access_locked?

    authenticated = Mfa::AuthenticationService.new(
      user: user,
      otp_code: params[:otp_code],
      backup_code: params[:backup_code]
    ).authenticate

    unless authenticated
      register_failed_mfa_attempt(user)
      return render_create_error_account_locked if user.access_locked?

      return render_mfa_error('errors.mfa.invalid_code')
    end

    sign_in_mfa_user(user)
  end

  def register_failed_mfa_attempt(user)
    user.with_lock do
      next if user.access_locked?

      user.unlock_access! if user.locked_at.present? # clear an expired lock before counting
      user.increment_failed_attempts
      user.lock_access! if user.failed_attempts >= Devise.maximum_attempts
    end
  end

  def sign_in_mfa_user(user)
    # Shared success path for MFA and device-verification sign-ins. Clear a stale lock
    # (the Warden reset hook zeroes failed_attempts but leaves locked_at) and the counter.
    user.unlock_access! if user.locked_at.present?
    user.reset_failed_attempts!
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

  def track_user_session
    client_id = @token&.try(:client) || response.headers['client']
    return unless client_id.present? && @resource.present?

    UserSessionTrackingService.new(
      user: @resource,
      request: request,
      client_id: client_id
    ).create_or_update!
  rescue StandardError => e
    Rails.logger.warn "Session tracking failed: #{e.message}"
  end
end

DeviseOverrides::SessionsController.prepend_mod_with('DeviseOverrides::SessionsController')
