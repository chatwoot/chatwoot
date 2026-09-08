# Triggered when an agent transitions to 'busy' status.
# Schedules itself to run after the account's configured timeout (in minutes).
# If the agent is still busy when the job runs, resets them to 'offline'.
#
# Date modified: 12.05.2026
class BusyToOfflineResetJob < ApplicationJob
  queue_as :scheduled_jobs

  # rubocop:disable Metrics/CyclomaticComplexity -- guard chain
  def perform(account_id, user_id, _busy_since)
    account = Account.find_by(id: account_id)
    return unless account

    timeout_minutes = account.busy_to_offline_timeout&.to_i
    return if timeout_minutes.blank? || timeout_minutes <= 0

    account_user = account.account_users.find_by(user_id: user_id)
    return unless account_user

    account_user.with_lock do
      return unless account_user.busy?

      busy_period = AgentActivityLog.where(account_id: account_id, user_id: user_id, status: 'busy', ended_at: nil).order(:started_at).last!
      return if busy_period.started_at > timeout_minutes.minutes.ago

      account_user.update!(availability: :offline)
      Rails.logger.info("[BusyToOfflineResetJob] Reset user #{user_id} to offline in account #{account_id}")
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
