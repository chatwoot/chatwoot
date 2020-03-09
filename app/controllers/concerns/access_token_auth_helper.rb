module AccessTokenAuthHelper
  BOT_ACCESSIBLE_ENDPOINTS = {
    'api/v1/accounts/conversations' => ['toggle_status'],
    'api/v1/accounts/conversations/messages' => ['create']
  }.freeze

  def authenticate_access_token!
    access_token = AccessToken.find_by(token: request.headers[:api_access_token])
    render_unauthorized('Invalid Access Token') && return unless access_token
    token_owner = access_token.owner
    @resource = token_owner
  end

  def validate_bot_access_token!
    return if current_user.is_a?(User)
    return if agent_bot_accessible?

    render_unauthorized('Access to this endpoint is not authorized for bots')
  end

  def agent_bot_accessible?
    BOT_ACCESSIBLE_ENDPOINTS.fetch(params[:controller], []).include?(params[:action])
  end
end
