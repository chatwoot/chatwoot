class Notification::PushNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification)
    Notification::PushNotificationService.new(notification: notification).perform
  end
end
