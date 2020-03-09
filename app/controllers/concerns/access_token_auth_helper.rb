module AccessTokenAuthHelper
  def authenticate_access_token!
    access_token = AccessToken.find_by(token: request.headers[:api_access_token])
    render_unauthorized('Invalid Access Token') && return unless access_token
    @resource = access_token.owner
  end
end
