class Instagram::Direct::MessageText < Instagram::WebhooksBaseService
  include HTTParty

  attr_reader :messaging

  base_uri 'https://graph.instagram.com/v22.0/'

  def initialize(messaging, channel)
    super(channel)
    @messaging = messaging
  end

  def perform
    instagram_id, contact_id = instagram_and_contact_ids
    inbox_channel(instagram_id)

    return if @inbox.blank?

    if @inbox.channel.reauthorization_required?
      Rails.logger.info("Skipping message processing as reauthorization is required for inbox #{@inbox.id}")
      return
    end

    return un_send_message if message_is_deleted?

    ensure_contact(contact_id) if contacts_first_message?(contact_id)

    Rails.logger.info("Instagram Direct Message Text: #{@messaging}")

    create_message
  end

  private

  def instagram_and_contact_ids
    if agent_message_via_echo?
      [@messaging[:sender][:id], @messaging[:recipient][:id]]
    else
      [@messaging[:recipient][:id], @messaging[:sender][:id]]
    end
  end

  # rubocop:disable Metrics/AbcSize
  def ensure_contact(ig_scope_id)
    begin
      fields = 'name,username,profile_pic'
      url = "https://graph.instagram.com/v22.0/#{ig_scope_id}?fields=#{fields}&access_token=#{@inbox.channel.access_token}"
      Rails.logger.info("Instagram ID: #{ig_scope_id}")
      Rails.logger.info("URL: #{url}")
      response = HTTParty.get(url)

      if response.success?
        result = JSON.parse(response.body).with_indifferent_access
        # Ensure all fields are present and in the same format
        result = {
          'name' => result['name'],
          'username' => result['username'],
          'profile_pic' => result['profile_pic'],
          'id' => result['id']
        }.with_indifferent_access
      else
        Rails.logger.error("Instagram API Error: #{response.code} - #{response.body}")
        result = {}
      end
    rescue HTTParty::Error => e
      @inbox.channel.authorization_error! if e.response&.code == 401
      Rails.logger.warn("Authorization error for account #{@inbox.account_id} for inbox #{@inbox.id}")
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    rescue StandardError => e
      Rails.logger.warn("[InstagramUserFetchError]: account_id #{@inbox.account_id} inbox_id #{@inbox.id}")
      Rails.logger.warn("[InstagramUserFetchError]: #{e.message}")
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    end

    find_or_create_contact(result) if defined?(result) && result.present?
  end
  # rubocop:enable Metrics/AbcSize

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

  def un_send_message
    message_to_delete = @inbox.messages.find_by(
      source_id: @messaging[:message][:mid]
    )
    return if message_to_delete.blank?

    message_to_delete.attachments.destroy_all
    message_to_delete.update!(content: I18n.t('conversations.messages.deleted'), deleted: true)
  end

  def create_message
    Rails.logger.info("Contact Inbox: #{@contact_inbox}")
    Rails.logger.info("Inbox: #{@inbox}")
    Rails.logger.info("Agent Message via Echo: #{agent_message_via_echo?}")
    return unless @contact_inbox

    Messages::Instagram::MessageBuilder.new(@messaging, @inbox, outgoing_echo: agent_message_via_echo?).perform
  end
end
