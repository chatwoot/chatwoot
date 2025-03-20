class Instagram::CallbacksController < ApplicationController
  include InstagramConcern
  include Instagram::IntegrationHelper

  def show
    @response = oauth_client.auth_code.get_token(
      oauth_code,
      redirect_uri: "#{base_url}/#{provider_name}/callback",
      grant_type: 'authorization_code'
    )

    @long_lived_token_response = exchange_for_long_lived_token(@response.token)
    inbox, already_exists = create_channel_with_inbox
    redirect_to app_instagram_inbox_agents_url(account_id: account_id, inbox_id: inbox.id)
  rescue StandardError => e
    Rails.logger.error("Instagram Channel creation Error: #{e.message}")
    ChatwootExceptionTracker.new(e).capture_exception
    error_info = if e.is_a?(OAuth2::Error)
                   begin
                     JSON.parse(e.message)
                   rescue JSON::ParseError
                     { 'error_type' => 'OAuthException', 'code' => 400, 'error_message' => e.message }
                   end
                 else
                   { 'error_type' => e.class.name, 'code' => 500, 'error_message' => e.message }
                 end

    redirect_to app_new_instagram_inbox_url(
      account_id: account_id,
      error_type: error_info['error_type'],
      code: error_info['code'],
      error_message: error_info['error_message']
    )
  end

  private

  def create_channel_with_inbox
    ActiveRecord::Base.transaction do
      expires_at = Time.current + @long_lived_token_response['expires_in'].seconds

      user_details = fetch_instagram_user_details(@long_lived_token_response['access_token'])

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
    return unless params[:state]

    verify_instagram_token(params[:state])
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
