class Api::V1::Accounts::Tiktok::AuthorizationsController < Api::V1::Accounts::OauthAuthorizationController
  include Tiktok::IntegrationHelper

  def create
    redirect_url = Tiktok::AuthClient.authorize_url(
      state: generate_tiktok_token(Current.account.id)
    )

    if redirect_url
      render json: { success: true, url: redirect_url }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end
end
