class Instagram::CallbacksController < ApplicationController
  include InstagramConcern

  def show
    Rails.logger.info("Instagram OAuth Code: #{oauth_code}")

    @response = oauth_client.auth_code.get_token(
      oauth_code,
      redirect_uri: "#{base_url}/#{provider_name}/callback",
      grant_type: 'authorization_code'
    )
    Rails.logger.info("Initial token response: #{@response.inspect}")

    @long_lived_token_response = exchange_for_long_lived_token(@response.token)
    Rails.logger.info("Long-lived token response: #{@long_lived_token_response}")

    inbox, already_exists = create_channel_with_inbox
    redirect_to app_instagram_inbox_agents_url(account_id: account_id, inbox_id: inbox.id)
  rescue StandardError => e
    Rails.logger.error("Instagram Channel creation Error: #{e.message}")
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_to '/'
  end

  private

  def create_channel_with_inbox
    ActiveRecord::Base.transaction do
      Rails.logger.info('Creating channel with inbox')

      expires_at = Time.current + @long_lived_token_response['expires_in'].seconds
      Rails.logger.info("Expires at: #{expires_at}")

      # Get Instagram user details
      user_details = fetch_instagram_user_details(@long_lived_token_response['access_token'])
      Rails.logger.info("Instagram user details: #{user_details.inspect}")

      channel_instagram = Channel::Instagram.create!(
        access_token: @long_lived_token_response['access_token'],
        instagram_id: user_details['user_id'].to_s,
        account: account,
        expires_at: expires_at
      )

      account.inboxes.create!(
        account: account,
        channel: channel_instagram,
        name: user_details['username']
      )
    end
  end

  def oauth_client
    instagram_client
  end

  def account_id
    # TODO: Get the account id from the user details via cache
    1
  end

  def provider_name
    raise NotImplementedError
  end

  def oauth_code
    params[:code]
  end

  def account
    @account ||= Account.find(account_id)
  end

  def provider_name
    'instagram'
  end
end
