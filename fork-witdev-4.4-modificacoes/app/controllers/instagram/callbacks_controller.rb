class Instagram::CallbacksController < ApplicationController
  include InstagramConcern
  include Instagram::IntegrationHelper

  def show
    # Check if Instagram redirected with an error (user canceled authorization)
    # See: https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/business-login#canceled-authorization
    if params[:error].present?
      handle_authorization_error
      return
    end

    process_successful_authorization
  rescue StandardError => e
    handle_error(e)
  end

  private

  # Process the authorization code and create inbox
  def process_successful_authorization
    @response = instagram_client.auth_code.get_token(
      oauth_code,
      redirect_uri: "#{base_url}/#{provider_name}/callback",
      grant_type: 'authorization_code'
    )

    @long_lived_token_response = exchange_for_long_lived_token(@response.token)
    inbox, already_exists = find_or_create_inbox

    if already_exists
      redirect_to app_instagram_inbox_settings_url(account_id: account_id, inbox_id: inbox.id)
    else
      redirect_to app_instagram_inbox_agents_url(account_id: account_id, inbox_id: inbox.id)
    end
  end

  # Handle all errors that might occur during authorization
  # https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/business-login#sample-rejected-response
  def handle_error(error)
    Rails.logger.error("Instagram Channel creation Error: #{error.message}")
    ChatwootExceptionTracker.new(error).capture_exception

    error_info = extract_error_info(error)
    redirect_to_error_page(error_info)
  end

  # Extract error details from the exception
  def extract_error_info(error)
    if error.is_a?(OAuth2::Error)
      begin
        # Instagram returns JSON error response which we parse to extract error details
        JSON.parse(error.message)
      rescue JSON::ParseError
        # Fall back to a generic OAuth error if JSON parsing fails
        { 'error_type' => 'OAuthException', 'code' => 400, 'error_message' => error.message }
      end
    else
      # For other unexpected errors
      { 'error_type' => error.class.name, 'code' => 500, 'error_message' => error.message }
    end
  end

  # Handles the case when a user denies permissions or cancels the authorization flow
  # Error parameters are documented at:
  # https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/business-login#canceled-authorization
  def handle_authorization_error
    error_info = {
      'error_type' => params[:error] || 'authorization_error',
      'code' => 400,
      'error_message' => params[:error_description] || 'Authorization was denied'
    }

    Rails.logger.error("Instagram Authorization Error: #{error_info['error_message']}")
    redirect_to_error_page(error_info)
  end

  # Centralized method to redirect to error page with appropriate parameters
  # This ensures consistent error handling across different error scenarios
  # Frontend will handle the error page based on the error_type
  def redirect_to_error_page(error_info)
    redirect_to app_new_instagram_inbox_url(
      account_id: account_id,
      error_type: error_info['error_type'],
      code: error_info['code'],
      error_message: error_info['error_message']
    )
  end

  def find_or_create_inbox
    user_details = fetch_instagram_user_details(@long_lived_token_response['access_token'])
    channel_instagram = find_channel_by_instagram_id(user_details['user_id'].to_s)
    channel_exists = channel_instagram.present?

    if channel_instagram
      update_channel(channel_instagram, user_details)
    else
      channel_instagram = create_channel_with_inbox(user_details)
    end

    # reauthorize channel, this code path only triggers when instagram auth is successful
    # reauthorized will also update cache keys for the associated inbox
    channel_instagram.reauthorized!

    [channel_instagram.inbox, channel_exists]
  end

  def find_channel_by_instagram_id(instagram_id)
    Channel::Instagram.find_by(instagram_id: instagram_id, account: account)
  end

  def update_channel(channel_instagram, user_details)
    expires_at = Time.current + @long_lived_token_response['expires_in'].seconds

    channel_instagram.update!(
      access_token: @long_lived_token_response['access_token'],
      expires_at: expires_at
    )

    # Update inbox name if username changed
    channel_instagram.inbox.update!(name: user_details['username'])
    channel_instagram
  end

  def create_channel_with_inbox(user_details)
    ActiveRecord::Base.transaction do
      expires_at = Time.current + @long_lived_token_response['expires_in'].seconds

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

      channel_instagram
    end
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
