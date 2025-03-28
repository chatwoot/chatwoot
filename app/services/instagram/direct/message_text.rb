class Instagram::Direct::MessageText < Instagram::BaseMessageText
  include HTTParty

  attr_reader :messaging

  base_uri "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"

  def ensure_contact(ig_scope_id)
    result = fetch_instagram_user(ig_scope_id)
    find_or_create_contact(result) if result.present?
  end

  def fetch_instagram_user(ig_scope_id)
    fields = 'name,username,profile_pic,follower_count,is_user_follow_business,is_business_follow_user,is_verified_user'
    url = "#{self.class.base_uri}/#{ig_scope_id}?fields=#{fields}&access_token=#{@inbox.channel.access_token}"

    response = HTTParty.get(url)
    Rails.logger.info("Instagram Contact Response: #{response.body}")

    return process_successful_response(response) if response.success?

    handle_error_response(response)
    {}
  rescue HTTParty::Error => e
    handle_auth_error(e)
    {}
  rescue StandardError => e
    handle_standard_error(e)
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
    Rails.logger.error("Instagram API Error: #{response.code} - #{response.body}")
  end

  def handle_auth_error(error)
    if error.response&.code == 401
      @inbox.channel.authorization_error!
      Rails.logger.warn("Authorization error for account #{@inbox.account_id} for inbox #{@inbox.id}")
    end
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end

  def handle_standard_error(error)
    Rails.logger.warn("[InstagramUserFetchError]: account_id #{@inbox.account_id} inbox_id #{@inbox.id}")
    Rails.logger.warn("[InstagramUserFetchError]: #{error.message}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end

  def create_message
    return unless @contact_inbox

    Messages::Instagram::Direct::MessageBuilder.new(@messaging, @inbox, outgoing_echo: agent_message_via_echo?).perform
  end
end
