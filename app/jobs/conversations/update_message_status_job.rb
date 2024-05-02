class Conversations::UpdateMessageStatusJob < ApplicationJob
  queue_as :low

  # This job only support marking messages as read or delivered, update this array if we want to support more statuses
  VALID_STATUSES = %w[read delivered].freeze

  def perform(conversation_id, timestamp, status = :read)
    return unless VALID_STATUSES.include?(status.to_s)

    conversation = Conversation.find_by(id: conversation_id)

    return unless conversation

    # Mark every message created before the user's viewing time read or delivered
    conversation.messages.where(status: %w[sent delivered])
                .where.not(message_type: 'incoming')
                .where('messages.created_at <= ?', timestamp).find_each do |message|
      message.update!(status: status)
    end
  end
end
