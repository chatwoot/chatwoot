class Notification::PushNotificationJob < ApplicationJob
  queue_as :within_5_seconds

  def perform(notification)
    Notification::PushNotificationService.new(notification: notification).perform
  end
end
