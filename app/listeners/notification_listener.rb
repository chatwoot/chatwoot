class NotificationListener < BaseListener
  def conversation_created(event)
    conversation, _account, _timestamp = extract_conversation_and_account(event)
    return if conversation.bot?

    conversation.inbox.members.each do |agent|
      next unless agent.notification_settings.find_by(account_id: conversation.account_id).email_conversation_creation?

      AgentNotifications::ConversationNotificationsMailer.conversation_created(conversation, agent).deliver_later
    end
  end

  def assignee_changed(event)
    conversation, _account, _timestamp = extract_conversation_and_account(event)
    assignee = conversation.assignee
    return unless conversation.notifiable_assignee_change?
    return if conversation.bot?

    return unless assignee.notification_settings.find_by(account_id: conversation.account_id).email_conversation_assignment?

    AgentNotifications::ConversationNotificationsMailer.conversation_assigned(conversation, assignee).deliver_later
  end
end
