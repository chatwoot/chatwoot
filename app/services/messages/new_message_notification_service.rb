class Messages::NewMessageNotificationService
  pattr_initialize [:message!]

  def perform
    return unless message.notifiable?

    notify_participating_users
    notify_conversation_assignee
  end

  private

  delegate :conversation, :sender, :account, to: :message

  def notify_participating_users
    participating_users = conversation.conversation_participants.map(&:user)
    participating_users -= [sender] if sender.is_a?(User)

    participating_users.uniq.each do |participant|
      NotificationBuilder.new(
        notification_type: 'participating_conversation_new_message',
        user: participant,
        account: account,
        primary_actor: message
      ).perform
    end
  end

  def notify_conversation_assignee
    return if conversation.assignee.blank?
    return if assignee_already_notified_via_participation?
    return if conversation.assignee == sender

    NotificationBuilder.new(
      notification_type: 'assigned_conversation_new_message',
      user: conversation.assignee,
      account: account,
      primary_actor: message
    ).perform
  end

  def assignee_already_notified_via_participation?
    return unless conversation.conversation_participants.map(&:user).include?(conversation.assignee)

    # check whether participation notifcation is disabled for assignee
    notification_setting = conversation.assignee.notification_settings.find_by(account_id: account.id)
    notification_setting.public_send(:email_participating_conversation_new_message?) || notification_setting
      .public_send(:push_participating_conversation_new_message?)
  end
end
