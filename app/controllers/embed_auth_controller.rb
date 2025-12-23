# frozen_string_literal: true

class EmbedAuthController < ActionController::Base
  skip_before_action :verify_authenticity_token
  before_action :authenticate_via_token
  before_action :set_embed_headers

  private

  def set_embed_headers
    # Allow embedding from synkicrm.com.br (same domain)
    # Remove X-Frame-Options to allow same-origin embedding
    response.headers.delete('X-Frame-Options')
    # Set CSP to allow same-origin and synkicrm.com.br
    csp = "frame-ancestors 'self' https://synkicrm.com.br https://*.synkicrm.com.br http://localhost:* http://127.0.0.1:*"
    response.headers['Content-Security-Policy'] = csp
  end

  def auth
    # Token validation and authentication happens in before_action
    # Create session and redirect to embed inbox
    sign_in(:user, @user, store: true, bypass: false)
    
    # Store embed_jti in session for revocation checking
    session[:embed_jti] = @embed_token.jti
    session[:embed_mode] = true

    redirect_url = "/app/embed/inbox"
    redirect_url += "?inbox_id=#{@embed_token.inbox_id}" if @embed_token.inbox_id

    redirect_to redirect_url
  end

  private

  def authenticate_via_token
    token = params[:token]
    return render_unauthorized('Token missing') unless token

    result = EmbedTokenService.validate_and_authenticate(token)
    return render_unauthorized('Invalid or revoked token') unless result

    @user = result[:user]
    @account = result[:account]
    @embed_token = result[:embed_token]

    # Verify user has access to account
    account_user = AccountUser.find_by(account: @account, user: @user)
    return render_unauthorized('User does not have access to account') unless account_user
  end

  def render_unauthorized(message)
    render plain: message, status: :unauthorized
  end
end

