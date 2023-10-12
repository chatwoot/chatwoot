class Conversations::MarkMessagesAsReadJob < ApplicationJob
  queue_as :low

  def perform(conversation)
    conversation.messages.where(message_type: 'outgoing', status: %w[sent delivered]).find_each do |message|
      message.update!(status: 'read')
    end
  end
end
