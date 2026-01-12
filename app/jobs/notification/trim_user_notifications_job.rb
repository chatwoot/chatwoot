class Notification::TrimUserNotificationsJob < ApplicationJob
  queue_as :low

  NOTIFICATION_LIMIT = 300

  def perform(user_id)
    keep_ids = Notification.where(user_id: user_id)
                           .order(created_at: :desc)
                           .limit(NOTIFICATION_LIMIT)
                           .pluck(:id)

    return if keep_ids.size < NOTIFICATION_LIMIT

    # Delete all notifications NOT in the keep set
    # Safe for concurrent execution
    Notification.where(user_id: user_id)
                .where.not(id: keep_ids)
                .delete_all
  end
end
