class Instagram::MessageText < Instagram::WebhooksBaseService
  include HTTParty

  attr_reader :messaging

  base_uri 'https://graph.facebook.com/v11.0/'

  def initialize(messaging)
    super()
    @messaging = messaging
  end

  def perform
    create_test_text
    instagram_id, contact_id = instagram_and_contact_ids
    inbox_channel(instagram_id)
    # person can connect the channel and then delete the inbox
    return if @inbox.blank?

    # This channel might require reauthorization, may be owner might have changed the fb password
    if @inbox.channel.reauthorization_required?
      Rails.logger.info("Skipping message processing as reauthorization is required for inbox #{@inbox.id}")
      return
    end

    return unsend_message if message_is_deleted?

    ensure_contact(contact_id) if contacts_first_message?(contact_id)

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
      k = Koala::Facebook::API.new(@inbox.channel.page_access_token) if @inbox.facebook?
      result = k.get_object(ig_scope_id) || {}
    rescue Koala::Facebook::AuthenticationError => e
      @inbox.channel.authorization_error!
      Rails.logger.warn("Authorization error for account #{@inbox.account_id} for inbox #{@inbox.id}")
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    rescue StandardError, Koala::Facebook::ClientError => e
      Rails.logger.warn("[FacebookUserFetchClientError]: account_id #{@inbox.account_id} inbox_id #{@inbox.id}")
      Rails.logger.warn("[FacebookUserFetchClientError]: #{e.message}")
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

  def sent_via_test_webhook?
    @messaging[:sender][:id] == '12334' && @messaging[:recipient][:id] == '23245'
  end

  def unsend_message
    message_to_delete = @inbox.messages.find_by(
      source_id: @messaging[:message][:mid]
    )
    return if message_to_delete.blank?

    message_to_delete.attachments.destroy_all
    message_to_delete.update!(content: I18n.t('conversations.messages.deleted'), deleted: true)
  end

  def create_message
    return unless @contact_inbox

    Messages::Instagram::MessageBuilder.new(@messaging, @inbox, outgoing_echo: agent_message_via_echo?).perform
  end

  def create_test_text
    return unless sent_via_test_webhook?

    Rails.logger.info('Probably Test data.')

    messenger_channel = Channel::FacebookPage.last
    @inbox = ::Inbox.find_by(channel: messenger_channel)
    return unless @inbox

    @contact = create_test_contact

    @conversation ||= create_test_conversation(conversation_params)

    @message = @conversation.messages.create!(test_message_params)
  end

  def create_test_contact
    @contact_inbox = @inbox.contact_inboxes.where(source_id: @messaging[:sender][:id]).first
    unless @contact_inbox
      @contact_inbox ||= @inbox.channel.create_contact_inbox(
        'sender_username', 'sender_username'
      )
    end

    @contact_inbox.contact
  end

  def create_test_conversation(conversation_params)
    Conversation.find_by(conversation_params) || build_conversation(conversation_params)
  end

  def test_message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: 'incoming',
      source_id: @messaging[:message][:mid],
      content: @messaging[:message][:text],
      sender: @contact
    }
  end

  def build_conversation(conversation_params)
    Conversation.create!(
      conversation_params.merge(
        contact_inbox_id: @contact_inbox.id
      )
    )
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      additional_attributes: {
        type: 'instagram_direct_message'
      }
    }
  end
end
