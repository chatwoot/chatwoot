module MicrosoftConcern
  extend ActiveSupport::Concern

  def microsoft_client
    app_id = GlobalConfigService.load('AZURE_APP_ID', nil)
    app_secret = GlobalConfigService.load('AZURE_APP_SECRET', nil)
    tenant_id = GlobalConfigService.load('AZURE_TENANT_ID', nil)

    # Determine the endpoints based on whether a tenant ID is provided
    if tenant_id.present?
      authorize_url = "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/authorize"
      token_url = "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token"
    else
      authorize_url = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize'
      token_url = 'https://login.microsoftonline.com/common/oauth2/v2.0/token'
    end

    ::OAuth2::Client.new(app_id, app_secret,
                         {
                           site: 'https://login.microsoftonline.com',
                           authorize_url: authorize_url,
                           token_url: token_url
                         })
  end

  private

  def scope
    'offline_access https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send openid profile email'
  end
end
