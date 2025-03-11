class Api::V1::Accounts::Instagram::AuthorizationsController < Api::V1::Accounts::BaseController
  include InstagramConcern
  include Instagram::IntegrationHelper
  before_action :check_authorization

  def create
    redirect_url = instagram_client.auth_code.authorize_url(
      {
        redirect_uri: "#{base_url}/instagram/callback",
        scope: 'instagram_business_basic instagram_business_manage_messages instagram_business_manage_comments instagram_business_content_publish instagram_business_manage_insights',
        enable_fb_login: '0',
        force_authentication: '1',
        response_type: 'code',
        state: generate_instagram_token(Current.account.id)
      }
    )
    Rails.logger.info("Account ID: #{Current.account.id}")
    Rails.logger.info("Instagram Authorization URL: #{redirect_url}")
    if redirect_url
      render json: { success: true, url: redirect_url }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  private

  def check_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end
end
