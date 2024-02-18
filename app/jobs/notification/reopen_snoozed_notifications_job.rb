class Notification::ReopenSnoozedNotificationsJob < ApplicationJob
  queue_as :low

  def perform
    Notification.where(snoozed_until: 3.days.ago..Time.current).find_in_batches(batch_size: 100) do |notifications_batch|
      notifications_batch.each do |notification|
        update_notification(notification)
      end
    end
  end

  private

  def update_notification(notification)
    updated_meta = (notification.meta || {}).merge('last_snoozed_at' => notification.snoozed_until)

    notification.update!(
      snoozed_until: nil,
      updated_at: Time.current,
      last_activity_at: Time.current,
      meta: updated_meta,
      read_at: nil
    )
  end
end
