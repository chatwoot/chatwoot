class Notification::EmailNotificationService
  pattr_initialize [:notification!]

  def perform
    return unless user_subscribed_to_notification?

    # TODO : Clean up whatever happening over here
    AgentNotifications::ConversationNotificationsMailer.public_send(notification
      .notification_type.to_s, notification.primary_actor, notification.user).deliver_later
  end

  private

  def user_subscribed_to_notification?
    notification_setting = notification.user.notification_settings.find_by(account_id: notification.account.id)
    return true if notification_setting.public_send("email_#{notification.notification_type}?")

    false
  end
end
