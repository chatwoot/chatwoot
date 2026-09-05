class ChatQueue::Queue::ValidationService
  pattr_initialize [:account!]

  def valid_for_queue?(conversation)
    cid = conversation.id

    unless account.queue_enabled?
      Rails.logger.info("[QUEUE][add][conv=#{cid}] Skip: queue disabled for account #{account.id}")
      return false
    end

    if ConversationQueue.exists?(conversation_id: cid, status: :waiting)
      Rails.logger.info("[QUEUE][add][conv=#{cid}] Skip: already in queue")
      return false
    end

    true
  end
end
