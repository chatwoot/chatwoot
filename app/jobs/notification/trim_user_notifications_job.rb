class Notification::TrimUserNotificationsJob < ApplicationJob
  queue_as :low

  NOTIFICATION_LIMIT = 300

  def perform(user_id)
    excess_count = Notification.where(user_id: user_id).count - NOTIFICATION_LIMIT
    return if excess_count <= 0

    # Delete oldest notifications beyond the limit using efficient bulk delete
    Notification.where(user_id: user_id)
                .order(created_at: :asc)
                .limit(excess_count)
                .delete_all
  end
end
