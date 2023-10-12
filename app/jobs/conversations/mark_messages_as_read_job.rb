class Conversations::MarkMessagesAsReadJob < ApplicationJob
  queue_as :low

  def perform(conversation)
    # Mark every message created before the user's viewing time as read.
    conversation.messages.where(status: %w[sent delivered])
                .where.not(message_type: 'incoming')
                .where('created_at <= ?',
                       conversation.contact_last_seen_at).find_each do |message|
      message.update!(status: 'read')
    end
  end
end
