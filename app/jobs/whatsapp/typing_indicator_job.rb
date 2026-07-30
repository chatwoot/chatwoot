class Whatsapp::TypingIndicatorJob < ApplicationJob
  queue_as :high

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?

    # force: skip Redis throttle so agent/bot typing always marks the latest inbound as read
    Whatsapp::MarkReadTypingService.new(conversation: conversation, force: true).perform
  end
end
