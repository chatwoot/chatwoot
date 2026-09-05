# cat-fork: when an agent switches to 'busy' and the account has busy_to_offline_timeout
# configured, schedule BusyToOfflineResetJob to flip them back to 'offline' after the timeout.
module AccountUserBusyTrackerPatch
  def update_presence_in_redis
    super
    schedule_busy_reset if saved_change_to_availability? && busy?
  end

  private

  def schedule_busy_reset
    timeout_minutes = account.busy_to_offline_timeout&.to_i
    return if timeout_minutes.blank? || timeout_minutes <= 0

    Rails.logger.info("[BusyTracker] scheduling BusyToOfflineResetJob in #{timeout_minutes}m for user=#{user_id} account=#{account_id}")
    BusyToOfflineResetJob
      .set(wait: timeout_minutes.minutes)
      .perform_later(account_id, user_id, updated_at.to_i)
  end
end

Rails.application.config.after_initialize do
  AccountUser.prepend(AccountUserBusyTrackerPatch)
end
