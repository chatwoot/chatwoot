class Notification::PushNotificationService
  pattr_initialize [:notification!]

  def perform
    return unless user_subscribed_to_notification?
    # TODO: implement the push delivery logic here
  end

  private

  def user_subscribed_to_notification?
    notification_setting = notification.user.notification_settings.find_by(account_id: notification.account.id)
    return true if notification_setting.public_send("push_#{notification.notification_type}?")

    false
  end
end
