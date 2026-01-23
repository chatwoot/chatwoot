class Notification::RemoveOldNotificationJob < ApplicationJob
  queue_as :purgable

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
    # Find the cutoff timestamp (the NOTIFICATION_LIMIT-th most recent notification)
    cutoff_time = Notification.where(user_id: user_id)
                              .order(created_at: :desc)
                              .offset(NOTIFICATION_LIMIT)
                              .limit(1)
                              .pick(:created_at)

    return unless cutoff_time

    # Delete notifications older than the cutoff
    # This avoids race conditions: notifications created after finding the cutoff
    # will have timestamps >= cutoff_time and won't be incorrectly deleted
    Notification.where(user_id: user_id)
                .where('created_at < ?', cutoff_time)
                .delete_all
  end
end
