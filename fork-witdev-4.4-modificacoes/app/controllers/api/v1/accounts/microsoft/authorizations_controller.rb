class Api::V1::Accounts::Microsoft::AuthorizationsController < Api::V1::Accounts::OauthAuthorizationController
  include MicrosoftConcern

  def create
    redirect_url = microsoft_client.auth_code.authorize_url(
      {
        redirect_uri: "#{base_url}/microsoft/callback",
        scope: scope,
        state: state,
        prompt: 'consent'
      }
    )
    if redirect_url
      render json: { success: true, url: redirect_url }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end
end
