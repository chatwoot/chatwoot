class Microsoft::CallbacksController < OauthCallbackController
  private

  def provider_name
    'microsoft'
  end

  def handle_response
    inbox, already_exists = find_or_create_inbox

    if already_exists
      redirect_to app_microsoft_inbox_settings_url(account_id: account.id, inbox_id: inbox.id)
    else
      redirect_to app_microsoft_inbox_agents_url(account_id: account.id, inbox_id: inbox.id)
    end
  end

  def oauth_client
    app_id = GlobalConfigService.load('AZURE_APP_ID', nil)
    app_secret = GlobalConfigService.load('AZURE_APP_SECRET', nil)

    ::OAuth2::Client.new(app_id, app_secret,
                         {
                           site: 'https://login.microsoftonline.com',
                           authorize_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
                           token_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/token'
                         })
  end

  def update_channel(channel_email)
    channel_email.update!({
                            imap_login: users_data['email'], imap_address: 'outlook.office365.com',
                            imap_port: '993', imap_enabled: true,
                            provider: 'microsoft',
                            provider_config: {
                              access_token: parsed_body['access_token'],
                              refresh_token: parsed_body['refresh_token'],
                              expires_on: (Time.current.utc + 1.hour).to_s
                            }
                          })
  end
end
