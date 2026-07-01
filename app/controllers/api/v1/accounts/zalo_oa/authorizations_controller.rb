class Api::V1::Accounts::ZaloOa::AuthorizationsController < Api::V1::Accounts::OauthAuthorizationController
  include ZaloOa::IntegrationHelper

  def create
    redirect_url = ZaloOa::AuthClient.authorize_url(
      state: generate_zalo_token(Current.account.id)
    )

    if redirect_url
      render json: { success: true, url: redirect_url }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end
end
