class Api::V1::Accounts::Instagram::AuthorizationsController < Api::V1::Accounts::OauthAuthorizationController
  include InstagramConcern
  include Instagram::IntegrationHelper

  rescue_from Instagram::UnifiedLoginService::Error do |error|
    render json: { success: false, error: error.message }, status: :unprocessable_entity
  end

  def create
    if instagram_configuration_id.present?
      render json: { success: true, url: unified_login_url }
      return
    end

    # https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/business-login#step-1--get-authorization
    redirect_url = instagram_client.auth_code.authorize_url(
      {
        redirect_uri: "#{base_url}/instagram/callback",
        scope: REQUIRED_SCOPES.join(','),
        enable_fb_login: '0',
        force_reauth: 'true',
        response_type: 'code',
        state: authorization_state
      }
    )
    if redirect_url
      render json: { success: true, url: redirect_url }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  private

  def authorization_state
    inbox = Current.account.inboxes.where(channel_type: 'Channel::Instagram').find(params[:inbox_id]) if params[:inbox_id].present?
    generate_instagram_token(Current.account.id, params[:return_to], inbox_id: inbox&.id)
  end

  def unified_login_url
    query = {
      client_id: Instagram::UnifiedLoginService.credentials.fetch(:client_id),
      config_id: instagram_configuration_id,
      redirect_uri: "#{base_url}/instagram/callback",
      response_type: 'code',
      override_default_response_type: true,
      state: authorization_state
    }
    "https://www.facebook.com/dialog/oauth?#{query.to_query}"
  end
end
