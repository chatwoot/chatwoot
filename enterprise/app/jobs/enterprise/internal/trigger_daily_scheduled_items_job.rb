module Enterprise::Internal::TriggerDailyScheduledItemsJob
  def perform
    super

    Captain::Documents::ScheduleSyncsJob.perform_later
  end
end
