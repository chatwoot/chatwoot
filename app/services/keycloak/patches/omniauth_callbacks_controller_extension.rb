module Keycloak::Patches::OmniauthCallbacksControllerExtension
  def omniauth_success
    return keycloak_success if params[:provider] == 'openid_connect'

    super
  end

  # The full OIDC auth hash (id/access tokens) overflows the cookie session, so only the needed claims are kept.
  def redirect_callbacks
    return super unless params[:provider] == 'openid_connect'

    omniauth_auth = request.env['omniauth.auth']
    slim_info = omniauth_auth['info'].to_h.slice('email', 'name', 'email_verified')
    slim_info['email_verified'] = omniauth_auth.dig('extra', 'raw_info', 'email_verified') if slim_info['email_verified'].nil?
    session['dta.omniauth.auth'] = {
      'provider' => 'openid_connect',
      'info' => slim_info,
      'keycloak_roles' => ::Keycloak::RoleExtractor.new(omniauth_auth).roles
    }
    session['dta.omniauth.params'] = request.env['omniauth.params']

    redirect_to get_redirect_route(get_devise_mapping), { status: 307 }.merge(redirect_options)
  end

  private

  def keycloak_success
    @resource = ::Keycloak::LoginService.new(auth_hash).perform
    sign_in_user
  rescue ::Keycloak::LoginService::LoginError => e
    redirect_to login_page_url(error: e.message)
  end
end
