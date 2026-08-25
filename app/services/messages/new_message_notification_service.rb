class Messages::NewMessageNotificationService
  pattr_initialize [:message!]

  def perform
    return unless message.notifiable?

    notify_conversation_assignee
    notify_participating_users
    notify_users_watching_all_conversations
  end

  private

  delegate :conversation, :sender, :account, to: :message

  def notify_conversation_assignee
    return if conversation.assignee.blank?
    return if already_notified?(conversation.assignee)
    return if conversation.assignee == sender

    NotificationBuilder.new(
      notification_type: 'assigned_conversation_new_message',
      user: conversation.assignee,
      account: account,
      primary_actor: message.conversation,
      secondary_actor: message
    ).perform
  end

  def notify_participating_users
    participating_users = conversation.conversation_participants.map(&:user)
    participating_users -= [sender] if sender.is_a?(User)

    participating_users.uniq.each do |participant|
      next if already_notified?(participant)

      NotificationBuilder.new(
        notification_type: 'participating_conversation_new_message',
        user: participant,
        account: account,
        primary_actor: message.conversation,
        secondary_actor: message
      ).perform
    end
  end

  # Notifies every user who opted in to being alerted about all incoming messages,
  # even when the conversation is unassigned or handled by someone else.
  # NotificationBuilder drops the users who can't access the conversation and the
  # ones who don't have the flag enabled.
  def notify_users_watching_all_conversations
    return unless message.incoming?
    return if conversation.pending?

    account.users.each do |user|
      next if already_notified?(user)

      NotificationBuilder.new(
        notification_type: 'all_conversations_new_message',
        user: user,
        account: account,
        primary_actor: message.conversation,
        secondary_actor: message
      ).perform
    end
  end

  # The user could already have been notified via a mention or via assignment
  # So we don't need to notify them again
  def already_notified?(user)
    conversation.notifications.exists?(user: user, secondary_actor: message)
  end
end
