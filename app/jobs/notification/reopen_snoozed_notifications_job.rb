class Notification::ReopenSnoozedNotificationsJob < ApplicationJob
  queue_as :low

  def perform
    # rubocop:disable Rails/SkipsModelValidations
    Notification.where(snoozed_until: 3.days.ago..Time.current)
                .update_all(snoozed_until: nil, updated_at: Time.current, last_activity_at: Time.current, read_at: nil)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
