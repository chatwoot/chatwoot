class Microsoft::CallbacksController < ApplicationController
  include Api::V1::MicrosoftGraphHelper

  def show
    client = ::OAuth2::Client.new(
      ENV.fetch('AZURE_APP_ID', nil),
      ENV.fetch('AZURE_APP_SECRET', nil),
      {
        site: 'https://login.microsoftonline.com',
        authorize_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
        token_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/token'
      }
    )

    @response = client.auth_code.get_token(
      oauth_code,
      redirect_uri: "#{base_utl}/microsoft/callback"
    )

    ActiveRecord::Base.transaction do
      inbox = create_inbox
      ::Redis::Alfred.delete(permitted_params['current_account_id'])
      # ::microsoft::WebhookSubscribeService.new(inbox_id: inbox.id).perform
      redirect_to app_twitter_inbox_agents_url(account_id: account.id, inbox_id: inbox.id)
    end
  end

  private

  def base_url
    'http://localhost:3000/'
  end

  def oauth_code
    params[:code]
  end

  def users_data
    decoded_token = JWT.decode parsed_body[:id_token], nil, false
    decoded_token[0]
  end

  def parsed_body
    @parsed_body ||= @response.response.parsed
  end

  def account_id
    ::Redis::Alfred.get('current_account_id')
  end

  def account
    @account ||= Account.find(account_id)
  end

  def microsoft_app_redirect_url
    app_new_microsoft_inbox_url(account_id: account.id)
  end

  def ensure_access_token
    microsoft_client.access_token(
      oauth_token: permitted_params[:oauth_token],
      oauth_verifier: permitted_params[:oauth_verifier]
    )
  end

  def create_inbox
    channel_email = Channel::Email.create!(
      { account: account, email: users_data['email'],
        imap_login: users_data['email'], imap_address: 'outlook.office365.com',
        imap_port: '993', imap_enabled: true,
        provider: 'microsoft',
        provider_config: {
          access_token: parsed_body['access_token'],
          refresh_token: parsed_body['refresh_token'],
          expires_on: (Time.current.utc + 1.hour).to_s
        } }
    )

    account.inboxes.create!(
      account: account,
      name: users_data['name'],
      channel: channel_email
    )
  end

  def permitted_params
    params.permit(:oauth_token, :oauth_verifier, :denied)
  end
end
