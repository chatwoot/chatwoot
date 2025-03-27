class Instagram::Direct::MessageText < Instagram::BaseMessageText
  include HTTParty

  attr_reader :messaging

  base_uri "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"

  def perform
    instagram_id, contact_id = direct_instagram_and_contact_ids
    inbox_channel(instagram_id)

    return if @inbox.blank?

    if @inbox.channel.reauthorization_required?
      Rails.logger.info("Skipping message processing as reauthorization is required for inbox #{@inbox.id}")
      return
    end

    return un_send_message if message_is_deleted?

    ensure_contact(contact_id) if contacts_first_message?(contact_id)

    create_message
  end

  private

  def direct_instagram_and_contact_ids
    if agent_message_via_echo?
      [@messaging[:sender][:id], @messaging[:recipient][:id]]
    else
      [@messaging[:recipient][:id], @messaging[:sender][:id]]
    end
  end

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

  def agent_message_via_echo?
    @messaging[:message][:is_echo].present?
  end

  def message_is_deleted?
    @messaging[:message][:is_deleted].present?
  end

  # if contact was present before find out contact_inbox to create message
  def contacts_first_message?(ig_scope_id)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: ig_scope_id).last
    @contact_inbox.blank? && @inbox.channel.instagram_id.present?
  end

  def sent_via_test_webhook?
    @messaging[:sender][:id] == '12334' && @messaging[:recipient][:id] == '23245'
  end

  def un_send_message
    message_to_delete = @inbox.messages.find_by(
      source_id: @messaging[:message][:mid]
    )
    return if message_to_delete.blank?

    message_to_delete.attachments.destroy_all
    message_to_delete.update!(content: I18n.t('conversations.messages.deleted'), deleted: true)
  end

  def create_message
    return unless @contact_inbox

    Messages::Instagram::Direct::MessageBuilder.new(@messaging, @inbox, outgoing_echo: agent_message_via_echo?).perform
  end
end
