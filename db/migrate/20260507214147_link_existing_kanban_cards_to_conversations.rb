class LinkExistingKanbanCardsToConversations < ActiveRecord::Migration[7.1]
  def up
    KanbanCard.where(conversation_id: nil).find_each do |card|
      conv = Conversation.where(contact_id: card.contact_id, status: :open)
                         .order(created_at: :desc).first
      next unless conv

      card.update_columns(conversation_id: conv.id) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def down
    # no-op
  end
end
