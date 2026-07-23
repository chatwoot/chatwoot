class Whatsapp::TypingIndicatorJob < ApplicationJob
  queue_as :high

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?

    Whatsapp::MarkReadTypingService.new(conversation: conversation).perform
  end
end
