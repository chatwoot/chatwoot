# frozen_string_literal: true

module EmbedSessionVerification
  extend ActiveSupport::Concern

  included do
    before_action :verify_embed_session, if: :embed_mode?
  end

  private

  def embed_mode?
    session[:embed_mode] == true
  end

  def verify_embed_session
    embed_jti = session[:embed_jti]
    return unless embed_jti

    embed_token = EmbedToken.find_by(jti: embed_jti)
    
    # If token is revoked, force logout
    if embed_token.nil? || embed_token.revoked?
      session.clear
      render json: {
        error: 'Embed session revoked',
        message: 'This embedded session has been revoked. Please contact your administrator.'
      }, status: :unauthorized
    end
  end
end

