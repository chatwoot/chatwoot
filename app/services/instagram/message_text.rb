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

    handle_error_response(response)
    {}
  end

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

  def handle_error_response(response)
    parsed_response = response.parsed_response
    error_message = parsed_response.dig('error', 'message')
    error_code = parsed_response.dig('error', 'code')

    # https://developers.facebook.com/docs/messenger-platform/error-codes
    # Access token has expired or become invalid.
    channel.authorization_error! if error_code == 190

    Rails.logger.warn("[InstagramUserFetchError]: account_id #{@inbox.account_id} inbox_id #{@inbox.id}")
    Rails.logger.warn("[InstagramUserFetchError]: #{error_message} #{error_code}")

    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end

  def base_uri
    "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"
  end

  def create_message
    return unless @contact_inbox

    Messages::Instagram::MessageBuilder.new(@messaging, @inbox, outgoing_echo: agent_message_via_echo?).perform
  end
end
