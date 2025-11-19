# frozen_string_literal: true

class AutoAssignConversationJob < ApplicationJob
  queue_as :default

  # Retry 3 times with exponential backoff: 3s, 9s, 27s
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    Conversations::AutoAssignService.new(conversation).perform
  end
end
