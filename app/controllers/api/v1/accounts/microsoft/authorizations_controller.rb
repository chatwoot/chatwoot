class Api::V1::Accounts::Microsoft::AuthorizationsController < Api::V1::Accounts::BaseController
  include MicrosoftConcern
  before_action :check_authorization

  def create
    redirect_url = microsoft_client.auth_code.authorize_url({
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
