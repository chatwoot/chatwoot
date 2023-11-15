class Conversations::MarkMessagesAsReadJob < ApplicationJob
  queue_as :low

  def perform(conversation_id, timestamp)
    conversation = Conversation.find_by(id: conversation_id)

    return unless conversation

    # Mark every message created before the user's viewing time as read.
    conversation.messages.where(status: %w[sent delivered])
                .where.not(message_type: 'incoming')
                .where('messages.created_at <= ?', timestamp).find_each do |message|
      message.update!(status: 'read')
    end
  end
end
