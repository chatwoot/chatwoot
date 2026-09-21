module AccessTokenAuthHelper
  BOT_ACCESSIBLE_ENDPOINTS = {
    'api/v1/accounts/conversations' => %w[show toggle_status toggle_typing_status toggle_priority create update custom_attributes],
    'api/v1/accounts/conversations/messages' => ['create'],
    'api/v1/accounts/conversations/assignments' => ['create'],
    'api/v1/accounts/conversations/labels' => %w[index create]
  }.freeze

  def authenticate_by_access_token?
    legacy_access_token.present? || (bearer_authorization? && !dashboard_bearer_token?)
  end

  def ensure_access_token
    if conflicting_access_token_credentials?
      render json: { error: 'Conflicting authentication credentials' }, status: :bad_request
      return
    end

    token = bearer_authorization? ? bearer_access_token : legacy_access_token
    @access_token = AccessToken.find_by(token: token) if token.present?
  end

  def legacy_access_token
    request.headers[:api_access_token] || request.headers[:HTTP_API_ACCESS_TOKEN]
  end

  def bearer_authorization?
    request.authorization.to_s.match?(/\ABearer(?:\s|\z)/i)
  end

  def bearer_access_token
    request.authorization.to_s[%r{\ABearer +([A-Za-z0-9\-._~+/]+=*)\z}i, 1]
  end

  def dashboard_bearer_token?
    return false unless respond_to?(:decode_bearer_token, true)

    credentials = decode_bearer_token(request.authorization)
    credentials.is_a?(Hash) && %w[uid client access-token].all? { |key| credentials[key].present? }
  end

  def conflicting_access_token_credentials?
    return true if legacy_access_token.present? && request.authorization.present? && legacy_access_token != bearer_access_token
    return false unless bearer_authorization? && !dashboard_bearer_token?

    dashboard_credentials_present?
  end

  def dashboard_credentials_present?
    %w[uid client access-token].any? { |key| request.headers[key].present? || params[key].present? }
  end

  def authenticate_access_token!
    ensure_access_token
    return if performed?

    render_unauthorized('Invalid Access Token') && return if @access_token.blank?

    # NOTE: This ensures that current_user is set and available for the rest of the controller actions
    @resource = @access_token.owner
    Current.user = @resource if allowed_current_user_type?(@resource)
  end

  def allowed_current_user_type?(resource)
    return true if resource.is_a?(User)
    return true if resource.is_a?(AgentBot)

    false
  end

  def validate_bot_access_token!
    return if Current.user.is_a?(User)
    return if @resource.is_a?(AgentBot) && agent_bot_accessible?

    render_unauthorized('Access to this endpoint is not authorized for bots')
  end

  def agent_bot_accessible?
    BOT_ACCESSIBLE_ENDPOINTS.fetch(params[:controller], []).include?(params[:action])
  end
end
