module Enterprise::Internal::TriggerHourlyScheduledItemsJob
  # Enterprise syncs daily with a 4 hour jitter. Polling every 6 hours keeps it
  # from slipping a full day while avoiding duplicate picks inside the jitter window.
  ENTERPRISE_AUTO_SYNC_POLL_HOURS = 6

  def perform
    super

    Captain::Documents::ScheduleSyncsJob.perform_later('enterprise') if enterprise_auto_sync_due?
  end

  private

  def enterprise_auto_sync_due?
    (Time.current.utc.hour % ENTERPRISE_AUTO_SYNC_POLL_HOURS).zero?
  end
end
