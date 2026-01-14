class ChatQueue::Queue::NotificationService
  pattr_initialize [:conversation!]

  def send_queue_notification
    cid = conversation.id
    Rails.logger.info("[QUEUE][notify_queue][conv=#{cid}] Sending queue template")

    create_message!(queue_message)
  end

  def send_assigned_notification
    cid = conversation.id
    Rails.logger.info("[QUEUE][notify_assigned][conv=#{cid}] Sending assigned template")

    create_message!(I18n.t('queue.notifications.assigned_message'))
  end

  private

  attr_reader :conversation

  def queue_message
    conversation.account.queue_message.presence ||
      I18n.t('queue.notifications.queue_message')
  end

  def create_message!(text)
    return unless conversation

    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :template,
      content: text
    )
  rescue StandardError => e
    Rails.logger.error("[QUEUE][notify][conv=#{conversation.id}] Error: #{e.message}")
    ChatwootExceptionTracker.new(
      e,
      account: conversation.account
    ).capture_exception
  end
end
