class EmailNotificationListener < BaseListener
  def conversation_created(event)
    conversation, _account, _timestamp = extract_conversation_and_account(event)
    return if conversation.bot?

    conversation.inbox.members.each do |agent|
      next unless agent.notification_settings.find_by(account_id: conversation.account_id).conversation_creation?

      AgentNotifications::ConversationNotificationsMailer.conversation_created(conversation, agent).deliver_later
    end
  end
end
