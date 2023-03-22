class Api::V1::Accounts::Microsoft::AuthorizationsController < Api::V1::Accounts::BaseController
  include MicrosoftConcern
  before_action :check_authorization

  def create
    email = params[:authorization][:email]
    redirect_url = microsoft_client.auth_code.authorize_url(auth_params)
    if redirect_url
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

  # SMTP, Pop and IMAP are being deprecated by Outlook.
  # https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/deprecation-of-basic-authentication-exchange-online
  #
  # As such, Microsoft has made it a real pain to use them.
  # If AZURE_TENANT_ID is set, we will use the MS Graph API instead.
  def auth_params
    return graph_auth_params if ENV.fetch('AZURE_TENANT_ID', false)

    standard_auth_params
  end

  def standard_auth_params
    {
      redirect_uri: "#{base_url}/microsoft/callback",
      scope: 'offline_access https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send openid',
      prompt: 'consent'
    }
  end

  def graph_auth_params
    {
      redirect_uri: "#{base_url}/microsoft/callback",
      scope: 'offline_access https://graph.microsoft.com/Mail.Read https://graph.microsoft.com/Mail.Send openid',
      prompt: 'consent'
    }
  end
end
