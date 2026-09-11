# Resolves the widget session JWT from header, cookie, or (legacy) query string.
# New clients should not put cw_conversation in URLs (CWE-598).
# The HttpOnly cookie is only for document loads (GET /widget). Widget API
# auth must not read it: SameSite=None plus skipped CSRF would otherwise make
# the session ambient on cross-site requests.
module WidgetAuthToken
  COOKIE_NAME = 'cw_conversation'.freeze

  def widget_auth_token(allow_cookie: true)
    header_token.presence || (allow_cookie && cookie_token.presence) || params[:cw_conversation].presence
  end

  def write_widget_auth_cookie(token)
    return if token.blank?

    local = Rails.env.local?
    cookies[COOKIE_NAME] = {
      value: token,
      httponly: true,
      secure: !local,
      same_site: local ? :lax : :none,
      expires: widget_cookie_expiry,
      path: '/'
    }
  end

  private

  def header_token
    bearer = request.authorization.to_s
    bearer_token = bearer.start_with?('Bearer ') ? bearer.delete_prefix('Bearer ') : nil
    request.headers['X-Auth-Token'].presence || bearer_token.presence
  end

  def cookie_token
    cookies[COOKIE_NAME]
  end

  def widget_cookie_expiry
    configured = InstallationConfig.find_by(name: 'WIDGET_TOKEN_EXPIRY')&.value
    days = (configured.presence || Widget::TokenService::DEFAULT_EXPIRY_DAYS).to_i
    days.days.from_now
  end
end
