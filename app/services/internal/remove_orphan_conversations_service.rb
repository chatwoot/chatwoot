class Internal::RemoveOrphanConversationsService
  def perform
    orphan_conversations = Conversation.where.missing(:contact)

    # Delete in batches to avoid memory issues and deadlocks
    Conversation.transaction do
      orphan_conversations.find_in_batches(batch_size: 1000) do |batch|
        conversation_ids = batch.map(&:id)
        Conversation.where(id: conversation_ids).delete_all
        Rails.logger.info "[RemoveOrphanConversationsService] Deleted #{batch.size} orphan conversations"
      end
    end
  end
end
