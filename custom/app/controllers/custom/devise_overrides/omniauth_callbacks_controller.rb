# Closes the OAuth/SAML side of the SSO-only lockdown. Google OAuth and SAML both
# funnel through #omniauth_success, which mints a valid sso_auth_token and hands
# it to the login page — a token the SessionsController lock cannot tell apart
# from a legitimate Platform-minted one. So without this, ENABLE_SSO_ONLY_LOGIN
# would only block password/MFA login and OAuth/SAML would silently bypass it.
#
# Blocking here, at the single provider entry point BEFORE any token is minted,
# makes the flag a true master lock regardless of ENABLE_GOOGLE_OAUTH_LOGIN /
# ENABLE_SAML_SSO_LOGIN. The Platform SSO handoff (§4.5) and impersonation do not
# pass through omniauth, so they are unaffected. Inert by default: with the flag
# unset this is a straight `super`.
module Custom::DeviseOverrides::OmniauthCallbacksController
  include Custom::Concerns::SsoOnlyLogin

  def omniauth_success
    return super unless sso_only_login_enabled?

    redirect_to login_page_url(error: 'sso-only-login')
  end
end
