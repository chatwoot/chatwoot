class ForwardNotificationJob < ApplicationJob
  queue_as :high

  def perform(message_id)
    message = Message.find(message_id)
    ForwardNotificationService.new(message).perform_notification_sending
  end
end