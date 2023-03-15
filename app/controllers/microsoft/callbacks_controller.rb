class Microsoft::CallbacksController < ApplicationController
  include MicrosoftConcern

  def show
    @response = microsoft_client.auth_code.get_token(
      oauth_code,
      redirect_uri: "#{base_url}/microsoft/callback"
    )

    inbox = find_or_create_inbox
    ::Redis::Alfred.delete(users_data['email'])
    redirect_to app_microsoft_inbox_agents_url(account_id: account.id, inbox_id: inbox.id)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_to '/'
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

  def find_or_create_inbox
    channel_email = Channel::Email.find_by(email: users_data['email'], account: account)
    channel_email ||= create_microsoft_channel_with_inbox
    update_microsoft_channel(channel_email)
    channel_email.inbox
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
