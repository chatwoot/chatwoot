# Unauthenticated endpoint for resending confirmation emails during signup.
# This is a standalone controller (not on DeviseOverrides::ConfirmationsController)
# because OmniAuth middleware intercepts all POST /auth/* routes as provider
# callbacks, and Devise controller filters cause 307 redirects for custom actions.
# Inherits from ActionController::API to avoid both issues entirely.
# Rate-limited by Rack::Attack (IP + email) and gated by hCaptcha.
class Auth::ResendConfirmationsController < ActionController::API
  SHOPIFY_INSTALL_REDIRECT_PATTERN = %r{\Asettings/integrations/shopify\?shopify_pending_install=[0-9a-f]{32}\z}

  def create
    return head(:ok) unless ChatwootCaptcha.new(params[:h_captcha_client_response]).valid?

    email = params[:email]
    return head(:ok) unless email.is_a?(String)

    user = User.from_email(email.strip.downcase)
    send_confirmation_instructions(user) if user && !user.confirmed?
    head :ok
  end

  private

  def confirmation_redirect_url
    redirect_url = params[:redirect_url].to_s
    redirect_url if redirect_url.match?(SHOPIFY_INSTALL_REDIRECT_PATTERN)
  end

  def send_confirmation_instructions(user)
    return user.send_confirmation_instructions unless confirmation_redirect_url

    user.send_confirmation_instructions_with_redirect(redirect_url: confirmation_redirect_url)
  end
end
