class Internal::TriggerHourlyScheduledItemsJob < ApplicationJob
  queue_as :within_10_minutes

  def perform
    Channels::Whatsapp::HealthSyncSchedulerJob.perform_later
  end
end

Internal::TriggerHourlyScheduledItemsJob.prepend_mod_with('Internal::TriggerHourlyScheduledItemsJob')
