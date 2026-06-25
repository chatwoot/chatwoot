class DeviseOverrides::SessionsController < DeviseTokenAuth::SessionsController
  MAX_SESSIONS = ENV.fetch('MAX_USER_SESSIONS', 25).to_i

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
    return if user && enforce_session_limit_for_password_login(user)

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

  def sessions_limit_reached?(user)
    active_token_count(user) >= MAX_SESSIONS
  end

  def active_token_count(user)
    now = Time.current.to_i
    (user.tokens || {}).count { |_, v| v['expiry'].to_i > now }
  end

  # Returns true when a response has been rendered (e.g., 409 picker). Non-browser clients
  # auto-evict instead of getting stuck on a UI they can't render.
  def enforce_session_limit_for_password_login(user)
    if revoking_sessions?
      revoke_sessions_for_login(user)
      return false
    end

    return false unless sessions_limit_reached?(user)

    # Picker only when every token has a tracked session; partial tracking would
    # show a misleading count, so fall through to silent eviction instead.
    if browser_request? && user.user_sessions.count >= user.tokens.size
      handle_sessions_limit_for_login(user)
      true
    else
      evict_oldest_session(user)
      false
    end
  end

  def browser_request?
    request.user_agent.to_s.include?('Mozilla')
  end

  def revoking_sessions?
    params[:revoke_session_id].present? || params[:revoke_all_sessions].present?
  end

  def revoke_sessions_for_login(user)
    if params[:revoke_all_sessions].present?
      user.tokens = {}
      user.save!
      user.user_sessions.destroy_all
    elsif params[:revoke_session_id].present?
      session = user.user_sessions.find_by(id: params[:revoke_session_id])
      return unless session

      user.tokens.delete(session.client_id)
      user.save!
      session.destroy!
    end
  end

  def evict_oldest_session(user)
    # Drop pre-rollout untracked tokens first so freshly tracked logins aren't evicted.
    return evict_oldest_token(user) if user.user_sessions.count < user.tokens.size

    oldest_session = user.user_sessions.order(Arel.sql('COALESCE(last_activity_at, created_at) ASC')).first
    return evict_oldest_token(user) unless oldest_session

    user.tokens.delete(oldest_session.client_id)
    user.save!
    oldest_session.destroy!
  end

  # Fallback if a token exists without a UserSession row (e.g., legacy data before tracking shipped).
  def evict_oldest_token(user)
    return if user.tokens.blank?

    oldest_client_id = user.tokens.min_by { |_, v| v['expiry'].to_i }&.first
    return unless oldest_client_id

    user.tokens.delete(oldest_client_id)
    user.save!
  end

  PICKER_SESSION_FIELDS = %i[id browser_name browser_version device_name platform_name platform_version
                             ip_address city country last_activity_at created_at].freeze

  def handle_sessions_limit_for_login(user)
    sessions = user.user_sessions.order(last_activity_at: :desc).map { |s| s.slice(*PICKER_SESSION_FIELDS) }
    render json: { sessions_limit_reached: true, sessions: sessions }, status: :conflict
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
