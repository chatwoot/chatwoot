class X::CallbacksController < ApplicationController
  include X::OAuthHelper

  def show
    return handle_authorization_error if params[:error].present?

    process_successful_authorization
  rescue StandardError => e
    handle_error(e)
  end

  private

  def process_successful_authorization
    decoded_state = jwt_decode(params[:state])
    code_verifier = decoded_state['code_verifier']

    token = auth_client.auth_code.get_token(
      params[:code],
      redirect_uri: "#{ENV.fetch('FRONTEND_URL', nil)}/x/callback",
      code_verifier: code_verifier
    )

    user_data = fetch_user_profile(token.token)
    inbox, already_exists = find_or_create_inbox(user_data, token)

    if already_exists
      redirect_to app_x_inbox_settings_url(account_id: account_id, inbox_id: inbox.id)
    else
      redirect_to app_x_inbox_agents_url(account_id: account_id, inbox_id: inbox.id)
    end
  end

  def handle_error(error)
    Rails.logger.error("X Channel creation Error: #{error.message}")
    ChatwootExceptionTracker.new(error).capture_exception

    error_info = if error.is_a?(OAuth2::Error)
                   parse_oauth_error(error)
                 else
                   { 'error_type' => error.class.name, 'code' => 500, 'error_message' => error.message }
                 end

    redirect_to_error_page(error_info)
  end

  def handle_authorization_error
    redirect_to_error_page(
      'error_type' => params[:error] || 'access_denied',
      'code' => 400,
      'error_message' => params[:error_description] || 'Authorization was denied'
    )
  end

  def redirect_to_error_page(error_info)
    redirect_to app_new_x_inbox_url(
      account_id: account_id,
      error_type: error_info['error_type'],
      code: error_info['code'],
      error_message: error_info['error_message']
    )
  end

  def parse_oauth_error(error)
    JSON.parse(error.message)
  rescue JSON::ParserError
    { 'error_type' => 'OAuthException', 'code' => 400, 'error_message' => error.message }
  end

  def find_or_create_inbox(user_data, token)
    channel = find_channel(user_data['id'])
    channel_exists = channel.present?

    if channel
      update_channel(channel, user_data, token)
      channel.subscribe_to_webhook
    else
      channel = create_channel_with_inbox(user_data, token)
    end

    channel.reauthorized!
    set_avatar(channel.inbox, user_data['profile_image_url']) if user_data['profile_image_url'].present?

    [channel.inbox, channel_exists]
  end

  def find_channel(profile_id)
    Channel::X.find_by(profile_id: profile_id, account: account)
  end

  def update_channel(channel, user_data, token)
    channel.update!(
      username: user_data['username'],
      name: user_data['name'],
      profile_image_url: user_data['profile_image_url'],
      bearer_token: token.token,
      refresh_token: token.refresh_token,
      token_expires_at: Time.current + token.expires_in.seconds,
      refresh_token_expires_at: 6.months.from_now
    )

    channel.inbox.update!(name: "X (@#{user_data['username']})")
  end

  def create_channel_with_inbox(user_data, token)
    ActiveRecord::Base.transaction do
      channel = Channel::X.create!(
        account: account,
        profile_id: user_data['id'],
        username: user_data['username'],
        name: user_data['name'],
        profile_image_url: user_data['profile_image_url'],
        bearer_token: token.token,
        refresh_token: token.refresh_token,
        token_expires_at: Time.current + token.expires_in.seconds,
        refresh_token_expires_at: 6.months.from_now
      )

      account.inboxes.create!(
        account: account,
        channel: channel,
        name: "X (@#{user_data['username']})"
      )

      channel
    end
  end

  def set_avatar(inbox, avatar_url)
    ::Avatar::AvatarFromUrlJob.perform_later(inbox, avatar_url)
  end

  def fetch_user_profile(access_token)
    response = HTTParty.get(
      'https://api.x.com/2/users/me',
      headers: {
        'Authorization' => "Bearer #{access_token}",
        'Content-Type' => 'application/json'
      },
      query: { 'user.fields' => 'profile_image_url,name,username' }
    )

    response.parsed_response['data']
  end

  def account_id
    @account_id ||= begin
      decoded_state = jwt_decode(params[:state])
      decoded_state['sub']
    end
  end

  def account
    @account ||= Account.find(account_id)
  end
end
