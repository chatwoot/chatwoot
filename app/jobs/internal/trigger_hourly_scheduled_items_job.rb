class Internal::TriggerHourlyScheduledItemsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform; end
end

Internal::TriggerHourlyScheduledItemsJob.prepend_mod_with('Internal::TriggerHourlyScheduledItemsJob')
