class Internal::RemoveOrphanConversationsService
  def perform
    orphan_conversations = Conversation.where.missing(:contact)
    total_deleted = 0

    Rails.logger.info '[RemoveOrphanConversationsService] Starting removal of orphan conversations'

    orphan_conversations.find_in_batches(batch_size: 1000) do |batch|
      conversation_ids = batch.map(&:id)
      Conversation.where(id: conversation_ids).delete_all
      total_deleted += batch.size
      Rails.logger.info "[RemoveOrphanConversationsService] Deleted #{batch.size} orphan conversations (#{total_deleted} total)"
    end
  end
end
