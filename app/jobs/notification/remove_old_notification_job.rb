class Notification::RemoveOldNotificationJob < ApplicationJob
  queue_as :low

  def perform
    Notification.where('created_at < ?', 1.month.ago)
                .find_each(batch_size: 1000, &:delete)
  end
end
