class Api::V1::Accounts::Microsoft::AuthorizationsController < Api::V1::Accounts::BaseController
  include MicrosoftConcern
  before_action :check_authorization

  def create
    redirect_url = microsoft_client.auth_code.authorize_url(
      {
        redirect_uri: "#{base_url}/microsoft/callback",
        scope: 'offline_access https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send openid profile',
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

  def state
    # return a signed id for the current account
    # this is cryptographically verifyable
    Current.account.to_sgid(expires_in: 15.minutes).to_s
  end

  private

  def check_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end
end
