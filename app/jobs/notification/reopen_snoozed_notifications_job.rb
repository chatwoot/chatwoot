class Notification::ReopenSnoozedNotificationsJob < ApplicationJob
  queue_as :low

  def perform
    Notification.where.not(snoozed_until: nil).where(snoozed_until: 3.days.ago..Time.current).find_each(batch_size: 100) do |notification|
      notification.update(snoozed_until: nil)
    end
  end
end
