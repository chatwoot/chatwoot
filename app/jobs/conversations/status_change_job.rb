class Conversations::StatusChangeJob < ApplicationJob
  queue_as :medium

  def perform(account:, conversation_ids:, status:)
    conversations = account.conversations.where(display_id: conversation_ids)
    conversations.update(status: status)
  end
end
