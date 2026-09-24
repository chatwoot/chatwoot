module AccessTokenAuthHelper
  BOT_ACCESSIBLE_ENDPOINTS = {
    'api/v1/accounts/conversations' => %w[show toggle_status toggle_typing_status toggle_priority create update custom_attributes],
    'api/v1/accounts/conversations/messages' => ['create'],
    'api/v1/accounts/conversations/assignments' => ['create'],
    'api/v1/accounts/conversations/labels' => %w[index create]
  }.freeze

  def authenticate_by_access_token?
    legacy_access_token.present? || (!bearer_access_token.nil? && !dashboard_bearer_token?)
  end

  def ensure_access_token
    token = bearer_access_token || legacy_access_token
    @access_token = AccessToken.find_by(token: token) if token.present?
  end

  def legacy_access_token
    request.headers[:api_access_token] || request.headers[:HTTP_API_ACCESS_TOKEN]
  end

  # TODO: Use request.bearer_token once we upgrade to a Rails version that provides it.
  def bearer_access_token
    scheme, token = request.authorization.to_s.split(' ', 2)
    # An empty credential must not fall back to another authentication method.
    token.to_s if scheme&.casecmp?('Bearer')
  end

  # Our dashboard UI uses DeviseTokenAuth, which can send login credentials in the Bearer header.
  # Let DeviseTokenAuth handle those credentials instead of treating them as API tokens.
  def dashboard_bearer_token?
    return false unless respond_to?(:decode_bearer_token, true)

    credentials = decode_bearer_token(request.authorization)
    credentials.is_a?(Hash) && credentials.values_at('uid', 'client', 'access-token').all?(&:present?)
  end

  def authenticate_access_token!
    ensure_access_token

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
