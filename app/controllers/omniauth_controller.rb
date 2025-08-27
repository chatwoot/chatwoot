class OmniauthController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_before_action :set_current_user
  skip_before_action :check_authorization

  def request
    # This will be handled by OmniAuth middleware
    # The request will be redirected to the IdP
  end

  def callback
    auth = request.env['omniauth.auth']
    account_id = params[:account_id]

    if auth.present?
      render json: {
        message: 'SAML authentication successful',
        account_id: account_id,
        provider: auth.provider,
        uid: auth.uid,
        info: {
          email: auth.info.email,
          name: auth.info.name,
          first_name: auth.info.first_name,
          last_name: auth.info.last_name
        },
        extra: {
          raw_info: auth.extra.raw_info
        }
      }
    else
      render json: {
        error: 'SAML authentication failed',
        message: request.env['omniauth.error'] || 'Unknown error'
      }, status: :unauthorized
    end
  end

  def failure
    render json: {
      error: 'SAML authentication failed',
      message: params[:message] || request.env['omniauth.error'] || 'Unknown error'
    }, status: :unauthorized
  end
end
