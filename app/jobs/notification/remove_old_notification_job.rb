class Notification::RemoveOldNotificationJob < ApplicationJob
  queue_as :low

  NOTIFICATION_LIMIT = 300
  OLD_NOTIFICATION_THRESHOLD = 1.month

  def perform
    remove_old_notifications
    trim_user_notifications
  end

  private

  def remove_old_notifications
    Notification.where('created_at < ?', OLD_NOTIFICATION_THRESHOLD.ago)
                .delete_all
  end

  def trim_user_notifications
    # Find users with more than NOTIFICATION_LIMIT notifications
    user_ids_exceeding_limit.each do |user_id|
      trim_notifications_for_user(user_id)
    end
  end

  def user_ids_exceeding_limit
    Notification.group(:user_id)
                .having('COUNT(*) > ?', NOTIFICATION_LIMIT)
                .pluck(:user_id)
  end

  def trim_notifications_for_user(user_id)
    # Keep the most recent NOTIFICATION_LIMIT notifications, delete the rest
    keep_ids = Notification.where(user_id: user_id)
                           .order(created_at: :desc)
                           .limit(NOTIFICATION_LIMIT)
                           .pluck(:id)

    Notification.where(user_id: user_id)
                .where.not(id: keep_ids)
                .delete_all
  end
end
