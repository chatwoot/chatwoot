class Api::V1::Accounts::GooglePlay::AuthorizationsController < Api::V1::Accounts::OauthAuthorizationController
  include GooglePlayOauthConcern

  def create
    redirect_url = google_client.auth_code.authorize_url(
      redirect_uri: google_play_callback_url,
      scope: scope,
      response_type: 'code',
      prompt: 'consent', # forces Google to return a refresh token
      access_type: 'offline',
      state: google_play_oauth_state,
      client_id: GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil)
    )

    if redirect_url
      render json: { success: true, url: redirect_url }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  private

  def google_play_oauth_state
    google_play_verifier.generate(
      {
        account_id: Current.account.id,
        app_id: params[:app_id],
        inbox_name: params[:inbox_name]
      },
      expires_in: 15.minutes
    )
  end
end
