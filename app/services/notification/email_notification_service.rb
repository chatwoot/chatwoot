class Notification::EmailNotificationService
  pattr_initialize [:notification!]

  def perform
    # don't send emails if user read the push notification already
    return if notification.read_at.present?
    return unless user_subscribed_to_notification?

    # TODO : Clean up whatever happening over here
    # Segregate the mailers properly
    AgentNotifications::ConversationNotificationsMailer.with(account: notification.account).public_send(notification
      .notification_type.to_s, notification.primary_actor, notification.user).deliver_now
  end

  private

  def user_subscribed_to_notification?
    notification_setting = notification.user.notification_settings.find_by(account_id: notification.account.id)
    return true if notification_setting.public_send("email_#{notification.notification_type}?")

    false
  end
end
