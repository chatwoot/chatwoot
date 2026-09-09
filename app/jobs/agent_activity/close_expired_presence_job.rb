class AgentActivity::CloseExpiredPresenceJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    AgentActivityLog.where(ended_at: nil).find_each do |log|
      expired_at = OnlineStatusTracker.get_presence_expiry(log.account_id, 'User', log.user_id)
      next unless expired_at && expired_at <= Time.zone.now

      AgentActivity::ActivityTracker.close_expired_presence(log.account_id, log.user_id, expired_at)
    end
  end
end
