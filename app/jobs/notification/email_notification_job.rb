class Notification::EmailNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification)
    # no need to send email if notification has been read already
    return if notification.read_at.present?

    Notification::EmailNotificationService.new(notification: notification).perform
  end
end
