class Conversations::ReopenSnoozedConversationsJob < ApplicationJob
  queue_as :low

  MAX_PROCESS_LIMIT = 500

  def perform(limit = MAX_PROCESS_LIMIT)
    reopened_count = 0

    snoozed_conversations.order(:snoozed_until).limit(limit).each do |conversation|
      conversation.open!
      reopened_count += 1
    end

    self.class.perform_later(limit) if reopened_count >= limit && snoozed_conversations.exists?
  end

  private

  def snoozed_conversations
    Conversation.where(status: :snoozed).where(snoozed_until: ..Time.current)
  end
end
