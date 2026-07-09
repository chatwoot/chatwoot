class Crm::Conversations::LastRealMessageAt
  # A "real" message is Message.chat (not activity, not private). Conversation#
  # last_activity_at is bumped by ANY message including system activity (assignee/
  # team changes, private notes), so it must never back-fill crm_cards.last_message_at
  # directly — that fallback is the CRM Kanban "Inatividade" filter root cause.
  # nil (no real message yet) is intentional and treated as stale by the filter.
  def self.for(conversation)
    return if conversation.blank?

    conversation.messages.chat.reorder(created_at: :desc).limit(1).pick(:created_at)
  end
end
