class Notification::PushNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification)
    # Access can be revoked between enqueue and delivery, so it is read again here.
    return unless notification.visible_to_recipient?

    Notification::PushNotificationService.new(notification: notification).perform
  end
end
