class Public::Api::V1::Inboxes::ConversationsController < Public::Api::V1::InboxesController
  def index
    @conversations = @contact_inbox.hmac_verified? ? @contact.conversations : @contact_inbox.conversations
  end

  def create
    @conversation = create_conversation
  end

  private

  def create_conversation
    ::Conversation.create!(conversation_params)
  end

  def conversation_params
    {
      account_id: @contact_inbox.contact.account_id,
      inbox_id: @contact_inbox.inbox_id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id
    }
  end
end
