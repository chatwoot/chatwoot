class Conversations::MarkMessagesAsReadJob < ApplicationJob
  queue_as :low

  def perform(inbox, timestamp)
    # Mark every message created before the user's viewing time as read.
    inbox.messages.where(status: %w[sent delivered])
         .where.not(message_type: 'incoming')
         .where('messages.created_at <= ?', timestamp).find_each do |message|
      message.update!(status: 'read')
    end
  end
end
