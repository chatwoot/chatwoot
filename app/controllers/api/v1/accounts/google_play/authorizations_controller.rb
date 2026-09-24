class Api::V1::Accounts::GooglePlay::AuthorizationsController < Api::V1::Accounts::OauthAuthorizationController
  include GooglePlayOauthConcern

  APP_ID_PATTERN = /\A[a-zA-Z][a-zA-Z0-9_]*(?:\.[a-zA-Z][a-zA-Z0-9_]*)+\z/

  before_action :validate_setup_fields

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

  def validate_setup_fields
    unless params[:app_id].is_a?(String) && APP_ID_PATTERN.match?(params[:app_id])
      return render_could_not_create_error(I18n.t('errors.google_play.invalid_app_id'))
    end

    return if params[:inbox_name].is_a?(String) && params[:inbox_name].present?

    render_could_not_create_error(I18n.t('errors.google_play.invalid_inbox_name'))
  end

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
