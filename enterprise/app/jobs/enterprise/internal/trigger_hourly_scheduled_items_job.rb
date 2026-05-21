module Enterprise::Internal::TriggerHourlyScheduledItemsJob
  def perform
    super

    Captain::Documents::ScheduleSyncsJob.perform_later
  end
end
