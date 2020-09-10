class NotificationListener < BaseListener
  def conversation_created(event)
    conversation, account = extract_conversation_and_account(event)
    return if conversation.bot?

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
    return unless conversation.notifiable_assignee_change?
    return if conversation.bot?

    NotificationBuilder.new(
      notification_type: 'conversation_assignment',
      user: assignee,
      account: account,
      primary_actor: conversation
    ).perform
  end

  def message_created(event)
    message, account = extract_message_and_account(event)
    conversation = message.conversation

    # only want to notify agents about customer messages
    return unless message.incoming?
    return unless conversation.assignee

    NotificationBuilder.new(
      notification_type: 'assigned_conversation_new_message',
      user: conversation.assignee,
      account: account,
      primary_actor: conversation
    ).perform
  end
end
