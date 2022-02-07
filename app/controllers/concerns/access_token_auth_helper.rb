module AccessTokenAuthHelper
  BOT_ACCESSIBLE_ENDPOINTS = {
    'api/v1/accounts/conversations' => %w[toggle_status create],
    'api/v1/accounts/conversations/messages' => ['create']
  }.freeze

  def ensure_access_token
    token = request.headers[:api_access_token] || request.headers[:HTTP_API_ACCESS_TOKEN]
    @access_token = AccessToken.find_by(token: token) if token.present?
  end

  def authenticate_access_token!
    ensure_access_token
    render_unauthorized('Invalid Access Token') && return if @access_token.blank?

    @resource = @access_token.owner
    Current.user = @resource if current_user.is_a?(User)
  end

  def validate_bot_access_token!
    return if Current.user.is_a?(User)
    return if agent_bot_accessible?

    render_unauthorized('Access to this endpoint is not authorized for bots')
  end

  def agent_bot_accessible?
    BOT_ACCESSIBLE_ENDPOINTS.fetch(params[:controller], []).include?(params[:action])
  end
end
