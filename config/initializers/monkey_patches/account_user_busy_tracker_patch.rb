# Monkey patch for AccountUser.
# When an agent transitions to 'busy' status and the account has
# busy_to_offline_timeout configured, schedules BusyToOfflineResetJob
# to automatically reset the agent to 'offline' after the timeout expires.
#
# Date modified: 12.05.2026
Rails.application.config.after_initialize do
  module AccountUserBusyTrackerPatch
    def update_presence_in_redis
      super
      Rails.logger.info("[BusyTracker] update_presence_in_redis called, availability=#{availability}, saved_change=#{saved_change_to_availability?.inspect}")
      schedule_busy_reset if saved_change_to_availability? && busy?
    end

    private

    def schedule_busy_reset
      timeout_minutes = account.busy_to_offline_timeout&.to_i
      Rails.logger.info("[BusyTracker] schedule_busy_reset called for user=#{user_id}, account=#{account_id}, timeout=#{timeout_minutes}")

      return if timeout_minutes.blank? || timeout_minutes <= 0

      Rails.logger.info("[BusyTracker] Scheduling BusyToOfflineResetJob in #{timeout_minutes} minutes for user=#{user_id}")
      BusyToOfflineResetJob
        .set(wait: timeout_minutes.minutes)
        .perform_later(account_id, user_id, updated_at.to_i)
    end
  end

  AccountUser.prepend(AccountUserBusyTrackerPatch)
end
