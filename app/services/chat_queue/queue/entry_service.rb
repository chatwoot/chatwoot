class ChatQueue::Queue::EntryService
  pattr_initialize [:account!]

  def prepare_for_queue!(conversation)
    clear_assignee_if_needed(conversation)
    create_queue_record(conversation)
    send_greeting_message(conversation)
    notify(conversation)
  end

  private

  def send_greeting_message(conversation)
    inbox = conversation.inbox

    return if inbox.active_bot?
    return unless inbox.greeting_enabled? && inbox.greeting_message.present?

    cid = conversation.id

    already_sent = conversation.messages
                               .where(message_type: :outgoing)
                               .exists?(content: inbox.greeting_message)
    if already_sent
      Rails.logger.info("[QUEUE][add][conv=#{cid}] Greeting already sent, skipping")
      return
    end

    Rails.logger.info("[QUEUE][add][conv=#{cid}] Sending greeting message")

    conversation.messages.create!(
      account: account,
      inbox: inbox,
      message_type: :outgoing,
      content: inbox.greeting_message,
      content_type: :text
    )
  end

  def clear_assignee_if_needed(conversation)
    return if conversation.assignee_id.blank?

    cid = conversation.id
    Rails.logger.info("[QUEUE][add][conv=#{cid}] Clearing assignee #{conversation.assignee_id}")
    conversation.update!(assignee_id: nil)
  end

  def create_queue_record(conversation)
    cid = conversation.id
    Rails.logger.info("[QUEUE][add][conv=#{cid}] Creating or updating queue entry")

    queue_record = ConversationQueue.find_or_initialize_by(conversation: conversation)
    is_requeue = queue_record.persisted? && !queue_record.waiting?

    Rails.logger.info("[QUEUE][add][conv=#{cid}] Re-queueing existing record (was #{queue_record.status})") if is_requeue

    queue_record.assign_attributes(
      account: account,
      inbox_id: conversation.inbox_id,
      queued_at: Time.current,
      status: :waiting,
      assigned_at: nil,
      left_at: nil
    )

    queue_record.save!

    QueueStatistic.increment_queued(account.id) unless is_requeue

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
