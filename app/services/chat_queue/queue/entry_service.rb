class ChatQueue::Queue::EntryService
  pattr_initialize [:account!]

  def prepare_for_queue!(conversation)
    clear_assignee_if_needed(conversation)
    create_queue_record(conversation)
    notify(conversation)
  end

  private

  def clear_assignee_if_needed(conversation)
    return if conversation.assignee_id.blank?

    cid = conversation.id
    Rails.logger.info("[QUEUE][add][conv=#{cid}] Clearing assignee #{conversation.assignee_id}")
    conversation.update!(assignee_id: nil)
  end

  def create_queue_record(conversation)
    cid = conversation.id
    Rails.logger.info("[QUEUE][add][conv=#{cid}] Creating queue entry")

    ConversationQueue.create!(
      conversation: conversation,
      account: account,
      inbox_id: conversation.inbox_id,
      queued_at: Time.current,
      status: :waiting
    )

    return if conversation.queued?

    Rails.logger.info("[QUEUE][add][conv=#{cid}] Updating conversation status to queued")
    conversation.update!(status: :queued)
  end

  def notify(conversation)
    cid = conversation.id
    Rails.logger.info("[QUEUE][add][conv=#{cid}] Sending queue notification")

    ChatQueue::Queue::NotificationService.new(conversation: conversation).send_queue_notification
    Queue::ProcessQueueJob.perform_later(account.id, conversation.inbox_id)
  end
end
