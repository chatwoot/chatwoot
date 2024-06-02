class Api::V1::Accounts::Google::AuthorizationsController < Api::V1::Accounts::BaseController
  include GoogleConcern
  before_action :check_authorization

  def create
    email = params[:authorization][:email]
    redirect_url = google_client.auth_code.authorize_url(
      {
        redirect_uri: "#{base_url}/google/callback",
        scope: 'email profile https://mail.google.com/',
        response_type: 'code',
        client_id: GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil)
      }
    )

    if redirect_url
      email = email.downcase
      ::Redis::Alfred.setex(email, Current.account.id, 5.minutes)
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
