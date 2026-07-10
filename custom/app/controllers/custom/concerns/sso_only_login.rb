# Shared gate for the SSO-only auth lockdown
# (docs/fork/CHATWOOT_ENGINE_INTEGRATION.md §4.6). When ENABLE_SSO_ONLY_LOGIN is
# on, the ONLY sanctioned way into a tenant account is the external stack's
# Platform SSO token (mintable solely with PLATFORM_TOKEN). Every native entry
# point — password, MFA-token, Google OAuth, SAML — must be refused. The gate
# lives here so the session and omniauth overlays enforce the exact same policy;
# drift between them would be a silent auth-bypass, so it must not be duplicated.
module Custom::Concerns::SsoOnlyLogin
  private

  def sso_only_login_enabled?
    # Explicit 'true' only: `!= 'false'` would treat a blank value (e.g. an
    # empty ENABLE_SSO_ONLY_LOGIN= line in .env makes GlobalConfigService
    # return nil) as ON and silently lock out every native login.
    GlobalConfigService.load('ENABLE_SSO_ONLY_LOGIN', 'false').to_s.downcase == 'true'
  end
end
