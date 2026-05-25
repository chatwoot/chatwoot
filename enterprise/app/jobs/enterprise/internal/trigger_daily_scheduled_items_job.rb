module Enterprise::Internal::TriggerDailyScheduledItemsJob
  # Poll each plan more often than its sync cadence, but not inside its jitter window.
  # Business syncs weekly with a 1 day jitter, so Tue/Thu/Sat polling catches due docs
  # without reselecting jobs that are still waiting to run.
  BUSINESS_AUTO_SYNC_WEEKDAYS = [Date::DAYNAMES.index('Tuesday'), Date::DAYNAMES.index('Thursday'), Date::DAYNAMES.index('Saturday')].freeze
  STARTUP_AUTO_SYNC_WEEKDAY = Date::DAYNAMES.index('Sunday')

  def perform
    super

    Captain::Documents::ScheduleSyncsJob.perform_later('business') if business_auto_sync_due?
    Captain::Documents::ScheduleSyncsJob.perform_later('startups') if startup_auto_sync_due?
  end

  private

  def business_auto_sync_due?
    BUSINESS_AUTO_SYNC_WEEKDAYS.include?(Time.current.utc.wday)
  end

  def startup_auto_sync_due?
    Time.current.utc.wday == STARTUP_AUTO_SYNC_WEEKDAY
  end
end
