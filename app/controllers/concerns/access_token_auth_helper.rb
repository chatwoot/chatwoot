module AccessTokenAuthHelper
  def authenticate_access_token!
    return unless request.headers[:api_access_token]

    access_token = AccessToken.find_by(token: request.headers[:api_access_token])
    render_unauthorized('Invalid Access Token') && return unless access_token
    bypass_sign_in(access_token.owner, scope: :user) if access_token.owner.is_a?(User)
    @resource = access_token.owner
  end
end
