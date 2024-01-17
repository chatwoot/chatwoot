class Notification::RemoveOldNotificationJob < ApplicationJob
  queue_as :low

  def perform
    old_notification_ids = Notification.where('created_at < ?', 1.month.ago)
                                       .pluck(:id)

    Notification.where(id: old_notification_ids).delete_all
  end
end
