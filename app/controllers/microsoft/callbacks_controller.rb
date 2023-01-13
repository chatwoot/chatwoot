class Microsoft::CallbacksController < ApplicationController
  include MicrosoftConcern

  def show
    @response = microsoft_client.auth_code.get_token(
      oauth_code,
      redirect_uri: "#{base_url}/microsoft/callback"
    )

    ActiveRecord::Base.transaction do
      inbox = find_or_create_inbox
      ::Redis::Alfred.delete(users_data['email' ])
      redirect_to app_microsoft_inbox_agents_url(account_id: account.id, inbox_id: inbox.id)
    rescue StandardError => e
      Rails.logger.error e
      redirect_to microsoft_app_redirect_url
    end
  end

  private

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
    ::Redis::Alfred.get(users_data['email'])
  end

  def account
    @account ||= Account.find(account_id)
  end

  def microsoft_app_redirect_url
    app_new_microsoft_inbox_url(account_id: account.id)
  end

  def find_or_create_inbox
    channel_email = create_imap_email_channel

    return channel_email.inbox if channel_email.inbox.presence

    account.inboxes.create_or_find_by!(
      account: account,
      channel: channel_email,
      name: users_data['name']
    )
  end

  def create_imap_email_channel
    channel_email = Channel::Email.find_or_create_by!(email: users_data['email'], account: account)
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
    channel_email
  end
end
