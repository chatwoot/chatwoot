class ConversationPriorityUpdateJob < ApplicationJob
  queue_as :low

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation&.open?

    ConversationPriorityService.new(conversation).calculate_and_update!
  rescue StandardError => e
    Rails.logger.error("Failed to update priority for conversation #{conversation_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end
