class Digitaltolk::RelatedEmailService
  attr_accessor :conversation_id

  LIMIT_EMAILS = 5

  def initialize(conversation_id)
    @conversation_id = conversation_id
  end

  def perform
    fetch_related_email
  end

  private

  def fetch_related_email
    return Conversation.none if conversation.blank?

    related_conversations.limit(LIMIT_EMAILS)
  end

  def conversation
    @conversation ||= Conversation.find_by(display_id: conversation_id)
  end

  def contact
    @contact ||= conversation.contact
  end

  def related_conversations
    contact.conversations.where.not(id: conversation.id)
  end
end
