class Microsoft::CallbacksController < OauthCallbackController
  def handle_response
    inbox, already_exists = find_or_create_inbox
    ::Redis::Alfred.delete(users_data['email'].downcase)

    if already_exists
      redirect_to app_microsoft_inbox_settings_url(account_id: account.id, inbox_id: inbox.id)
    else
      redirect_to app_microsoft_inbox_agents_url(account_id: account.id, inbox_id: inbox.id)
    end
  end

  private

  def provider_name
    'microsoft'
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

  def users_data
    decoded_token = JWT.decode parsed_body[:id_token], nil, false
    decoded_token[0]
  end

  def account_id
    ::Redis::Alfred.get(users_data['email'].downcase)
  end

  def account
    @account ||= Account.find(account_id)
  end

  def find_or_create_inbox
    channel_email = Channel::Email.find_by(email: users_data['email'], account: account)
    # we need this value to know where to redirect on sucessful processing of the callback
    channel_exists = channel_email.present?

    channel_email ||= create_microsoft_channel_with_inbox
    update_microsoft_channel(channel_email)

    # reauthorize channel, this code path only triggers when microsoft auth is successful
    # reauthorized will also update cache keys for the associated inbox
    channel_email.reauthorized!

    [channel_email.inbox, channel_exists]
  end

  # Fallback name, for when name field is missing from users_data
  def fallback_name
    users_data['email'].split('@').first.parameterize.titleize
  end

  def create_microsoft_channel_with_inbox
    ActiveRecord::Base.transaction do
      channel_email = Channel::Email.create!(email: users_data['email'], account: account)
      account.inboxes.create!(
        account: account,
        channel: channel_email,
        name: users_data['name'] || fallback_name
      )
      channel_email
    end
  end

  def update_microsoft_channel(channel_email)
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
