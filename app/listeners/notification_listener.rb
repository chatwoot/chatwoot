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

    # NOTE:  The issue was that when a team change results in an assignee being set to nil,
    # the system was still trying to create a notification about the assignment change,
    # but there was no assignee to notify, causing potential issues in the notification system.
    # We need to debug this properly, but for now no need to pollute the jobs
    return if assignee.blank?
    return if event.data[:notifiable_assignee_change].blank?
    return if conversation.pending?

    NotificationBuilder.new(
      notification_type: 'conversation_assignment',
      user: assignee,
      account: account,
      primary_actor: conversation
    ).perform
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]

    Messages::MentionService.new(message: message).perform
    Messages::NewMessageNotificationService.new(message: message).perform
  end
end
