class Notification::ReopenSnoozedNotificationsJob < ApplicationJob
  queue_as :low

  def perform
    Notification.where(snoozed_until: 3.days.ago..Time.current).find_each do |notification|
      updated_meta = (notification.meta || {}).merge('last_snoozed_at' => notification.snoozed_until)

      notification.update(
        snoozed_until: nil,
        updated_at: Time.current,
        last_activity_at: Time.current,
        meta: updated_meta
      )
    end
  end
end
