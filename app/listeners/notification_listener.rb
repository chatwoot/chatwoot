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

    NotificationBuilder.new(
      notification_type: 'conversation_assignment',
      user: assignee,
      account: account,
      primary_actor: conversation
    ).perform
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]

    return if ignore_message_created_event?(message)

    Messages::MentionService.new(message: message).perform
    Messages::NewMessageNotificationService.new(message: message).perform
  end

  def backpopulated_message?(message)
    message.additional_attributes['ignore_automation_rules'].present? && message.additional_attributes['ignore_automation_rules']
  end

  def ignore_notification_trigger?(message)
    message.additional_attributes['disable_notifications'].present? && message.additional_attributes['disable_notifications']
  end

  def ignore_message_created_event?(message)
    backpopulated_message?(message) || ignore_notification_trigger?(message)
  end
end
