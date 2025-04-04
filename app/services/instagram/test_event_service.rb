class Instagram::TestEventService
  def initialize(messaging)
    @messaging = messaging
  end

  def perform
    Rails.logger.info("Processing Instagram test webhook event, #{@messaging}")

    return false unless test_webhook_event?

    create_test_text
  end

  private

  def test_webhook_event?
    @messaging[:sender][:id] == '12334' && @messaging[:recipient][:id] == '23245'
  end

  def create_test_text
    # As of now, we are using the last created instagram channel as the test channel,
    # since we don't have any other channel for testing purpose at the time of meta approval
    channel = Channel::Instagram.last

    @inbox = ::Inbox.find_by(channel: channel)
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
