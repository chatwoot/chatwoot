class Notification::TrimUserNotificationsJob < ApplicationJob
  queue_as :purgable

  NOTIFICATION_LIMIT = 300

  def perform(user_id)
    # Capture timestamp before querying - notifications created after this are safe from deletion
    job_started_at = Time.current

    keep_ids = Notification.where(user_id: user_id)
                           .where('created_at <= ?', job_started_at)
                           .order(created_at: :desc)
                           .limit(NOTIFICATION_LIMIT)
                           .pluck(:id)

    return if keep_ids.size < NOTIFICATION_LIMIT

    # Delete notifications that existed when job started, excluding those we want to keep
    Notification.where(user_id: user_id)
                .where('created_at <= ?', job_started_at)
                .where.not(id: keep_ids)
                .delete_all
  end
end
