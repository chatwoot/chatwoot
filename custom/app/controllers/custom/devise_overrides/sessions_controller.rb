module Custom::DeviseOverrides::SessionsController
  # SaaS auth is owned by the external Next.js / NestJS stack; users are handed
  # into Chatwoot only via the Platform SSO login link
  # (docs/fork/CHATWOOT_ENGINE_INTEGRATION.md §4.5). When ENABLE_SSO_ONLY_LOGIN is
  # on, reject every non-SSO session create (password + MFA-token) so native
  # login cannot be used to bypass the external app — the sso_auth_token can only
  # be minted with the PLATFORM_TOKEN, so login stays server-to-server gated.
  #
  # Impersonation still works (it also arrives as an sso_auth_token). Super admin
  # uses a separate Devise scope (devise_for :super_admins) and is unaffected.
  # Inert by default: with the flag unset this is a straight `super`, so upstream
  # behaviour and specs are unchanged.
  def create
    return super unless sso_only_login_enabled?
    return super if sso_authentication_request?

    render json: {
      error: I18n.t('errors.sso_only_login'),
      error_code: 'sso_only_login'
    }, status: :unauthorized
  end

  private

  def sso_only_login_enabled?
    GlobalConfigService.load('ENABLE_SSO_ONLY_LOGIN', 'false').to_s != 'false'
  end
end
