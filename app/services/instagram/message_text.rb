class Instagram::MessageText < Instagram::BaseMessageText
  attr_reader :messaging

  def ensure_contact(ig_scope_id)
    result = fetch_instagram_user(ig_scope_id)
    find_or_create_contact(result) if result.present?
  end

  def fetch_instagram_user(ig_scope_id)
    fields = 'name,username,profile_pic,follower_count,is_user_follow_business,is_business_follow_user,is_verified_user'
    url = "#{base_uri}/#{ig_scope_id}?fields=#{fields}&access_token=#{@inbox.channel.access_token}"

    response = HTTParty.get(url)

    return process_successful_response(response) if response.success?

    handle_error_response(response, ig_scope_id) || {}
  end

  private

  def process_successful_response(response)
    result = JSON.parse(response.body).with_indifferent_access
    {
      'name' => result['name'],
      'username' => result['username'],
      'profile_pic' => result['profile_pic'],
      'id' => result['id'],
      'follower_count' => result['follower_count'],
      'is_user_follow_business' => result['is_user_follow_business'],
      'is_business_follow_user' => result['is_business_follow_user'],
      'is_verified_user' => result['is_verified_user']
    }.with_indifferent_access
  end

  def handle_error_response(response, ig_scope_id)
    parsed_response = response.parsed_response
    parsed_response = JSON.parse(parsed_response) if parsed_response.is_a?(String)
    error_message = parsed_response.dig('error', 'message')
    error_code = parsed_response.dig('error', 'code')

    # https://developers.facebook.com/docs/messenger-platform/error-codes
    # Access token has expired or become invalid.
    channel.authorization_error! if error_code == 190

    # TODO: Remove this once we have a better way to handle this error.
    # https://developers.facebook.com/docs/messenger-platform/instagram/features/user-profile/#user-consent
    # The error typically occurs when the connected Instagram account attempts to send a message to a user
    # who has never messaged this Instagram account before.
    # We can only get consent to access a user's profile if they have previously sent a message to the connected Instagram account.
    # In such cases, we receive the error "User consent is required to access user profile".
    # We can safely ignore this error.
    return if error_code == 230

    # The error occurs when Facebook tries to validate the Facebook App created to authorize Instagram integration.
    # The Facebook's agent uses a Bot to make tests on the App where is not a valid user via API,
    # returning `{"error"=>{"message"=>"No matching Instagram user", "type"=>"IGApiException", "code"=>9010}}`.
    # Then Facebook rejects the request saying this app is still not ready once the integration with Instagram didn't work.
    # We can safely create an unknown contact, making this integration work.
    return unknown_user(ig_scope_id) if error_code == 9010

    Rails.logger.warn("[InstagramUserFetchError]: account_id #{@inbox.account_id} inbox_id #{@inbox.id} ig_scope_id #{ig_scope_id}")
    Rails.logger.warn("[InstagramUserFetchError]: #{error_message} #{error_code}")

    exception = StandardError.new("#{error_message} (Code: #{error_code}, IG Scope ID: #{ig_scope_id})")
    ChatwootExceptionTracker.new(exception, account: @inbox.account).capture_exception
  end

  def base_uri
    "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"
  end

  def create_message
    return unless @contact_inbox

    Messages::Instagram::MessageBuilder.new(@messaging, @inbox, outgoing_echo: agent_message_via_echo?).perform
  end

  def unknown_user(ig_scope_id)
    {
      'name' => "Unknown (IG: #{ig_scope_id})",
      'id' => ig_scope_id
    }.with_indifferent_access
  end
end
