class NotificationListener < BaseListener
  def conversation_bot_handoff(event)
    conversation, account = extract_conversation_and_account(event)
    return if conversation.pending?

    conversation.inbox.members.each do |agent|
      NotificationBuilder.new(
        notification_type: 'conversation_creation',
        user: agent,
        account: account,
        primary_actor: conversation
      ).perform
    end
  end

  def conversation_created(event)
    conversation, account = extract_conversation_and_account(event)
    return if conversation.pending?

    conversation.inbox.members.each do |agent|
      NotificationBuilder.new(
        notification_type: 'conversation_creation',
        user: agent,
        account: account,
        primary_actor: conversation
      ).perform
    end
  end

  def assignee_changed(event)
    conversation, account = extract_conversation_and_account(event)
    assignee = conversation.assignee
    return if event.data[:notifiable_assignee_change].blank?
    return if conversation.pending?

    Rails.logger.info "[NotificationListener] Assignee changed for conversation: #{conversation.id} to #{assignee&.id} [#{assignee&.email}]"

    NotificationBuilder.new(
      notification_type: 'conversation_assignment',
      user: assignee,
      account: account,
      primary_actor: conversation
    ).perform
  rescue NoMethodError => e
    Rails.logger.error "[NotificationListener] Error in assignee_changed: #{e.message}"
    exception_tracker = ChatwootExceptionTracker.new(e, account: account,
                                                        additional_context: { 'conversation': conversation, 'assignee': assignee })
    exception_tracker.capture_exception
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]

    Messages::MentionService.new(message: message).perform
    Messages::NewMessageNotificationService.new(message: message).perform
  end
end
