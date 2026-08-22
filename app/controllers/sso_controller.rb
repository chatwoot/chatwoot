# Self-hosted SSO login: generates a short-lived, single-use SSO token for a
# resolved user and redirects to the login page, which auto-authenticates using
# the existing SSO token flow in DeviseOverrides::SessionsController.
#
# Inherits from ActionController::API (like Auth::ResendConfirmationsController)
# because the OmniAuth middleware intercepts /auth/* routes as provider callbacks,
# and to avoid Devise session filters on this intentionally unauthenticated path.
#
# Security note: this endpoint signs a user in without credentials. It is meant
# for trusted/self-hosted deployments and is deliberately gated by the
# ENABLE_INTERNAL_SSO_LOGIN flag. Restrict it (or keep it behind the flag) when
# the app is exposed to the public internet.
class SsoController < ActionController::API
  def create
    return render_not_available unless sso_login_enabled?

    user = resolve_sso_user
    return render_not_available unless user

    redirect_to sso_login_url(user), allow_other_host: true
  end

  private

  def sso_login_enabled?
    ENV.fetch('ENABLE_INTERNAL_SSO_LOGIN', 'true').to_s != 'false'
  end

  def resolve_sso_user
    return User.from_email(params[:email].strip.downcase) if params[:email].present?

    configured_user || default_sso_user
  end

  def configured_user
    User.from_email(ENV['SSO_LOGIN_EMAIL']) if ENV['SSO_LOGIN_EMAIL'].present?
  end

  def default_sso_user
    User.where(type: 'SuperAdmin').order(:created_at).first || User.order(:created_at).first
  end

  def sso_login_url(user)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    params = { email: user.email, sso_auth_token: user.generate_sso_auth_token }.to_query

    "#{frontend_url}/app/login?#{params}"
  end

  def render_not_available
    render json: { error: 'SSO login is not available' }, status: :unauthorized
  end
end
