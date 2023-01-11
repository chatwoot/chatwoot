class Api::V1::Accounts::Microsoft::AuthorizationsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def create
    client = ::OAuth2::Client.new(ENV.fetch('AZURE_APP_ID', nil), ENV.fetch('AZURE_APP_SECRET', nil),
                                  {
                                    site: 'https://login.microsoftonline.com',
                                    authorize_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
                                    token_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/token'
                                  })
    redirect_url = client.auth_code.authorize_url({
                                                    redirect_uri: "#{base_url}/microsoft/callback",
                                                    scope: 'offline_access https://outlook.office.com/IMAP.AccessAsUser.All
                                                            https://outlook.office.com/SMTP.Send openid',
                                                    prompt: 'consent'
                                                  })
    if redirect_url
      ::Redis::Alfred.setex('current_account_id', Current.account.id)
      render json: { success: true, url: redirect_url }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  private

  def check_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
