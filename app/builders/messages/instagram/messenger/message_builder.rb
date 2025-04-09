class Messages::Instagram::Messenger::MessageBuilder < Messages::Instagram::BaseMessageBuilder
  def initialize(messaging, inbox, outgoing_echo: false)
    super(messaging, inbox, outgoing_echo: outgoing_echo)
  end

  private

  def get_story_object_from_source_id(source_id)
    k = Koala::Facebook::API.new(@inbox.channel.page_access_token) if @inbox.facebook?
    k.get_object(source_id, fields: %w[story from]) || {}
  rescue Koala::Facebook::AuthenticationError
    @inbox.channel.authorization_error!
    raise
  rescue Koala::Facebook::ClientError => e
    # The exception occurs when we are trying fetch the deleted story or blocked story.
    @message.attachments.destroy_all
    @message.update!(content: I18n.t('conversations.messages.instagram_deleted_story_content'))
    Rails.logger.error e
    {}
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    {}
  end

  def find_conversation_scope
    Conversation.where(conversation_params)
                .where("additional_attributes ->> 'type' = 'instagram_direct_message'")
  end

  def additional_conversation_attributes
    { type: 'instagram_direct_message' }
  end
end
