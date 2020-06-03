class Notification::EmailNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification)
    Notification::EmailNotificationService.new(notification: notification).perform
  end
end
