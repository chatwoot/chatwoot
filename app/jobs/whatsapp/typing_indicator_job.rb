class Whatsapp::TypingIndicatorJob < ApplicationJob
  queue_as :low

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?

    Whatsapp::TypingIndicatorService.new(conversation: conversation).perform
  end
end
