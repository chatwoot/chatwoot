class AgentActivity::ActivityTracker
  def self.track_status_change(account_id, user_id, new_status)
    now = Time.zone.now

    AgentActivityLog.close_open_logs(account_id, user_id, now)

    AgentActivityLog.where(account_id: account_id, user_id: user_id, duration_seconds: nil)
                    .where.not(ended_at: nil)
                    .find_each do |log|
      log.update(duration_seconds: (log.ended_at - log.started_at).to_i)
    end

    return if new_status == 'offline'

    AgentActivityLog.create!(
      account_id: account_id,
      user_id: user_id,
      status: new_status,
      started_at: now
    )
  end

  def self.close_all_for_user(account_id, user_id)
    AgentActivityLog.close_open_logs(account_id, user_id, Time.zone.now)
  end

  def self.close_stale_logs(stale_threshold = OnlineStatusTracker::PRESENCE_DURATION + 5.minutes)
    stale_time = Time.zone.now - stale_threshold

    AgentActivityLog.where(ended_at: nil)
                    .where('started_at < ?', stale_time)
                    .find_each do |log|
      is_online = OnlineStatusTracker.get_presence(log.account_id, 'User', log.user_id)

      unless is_online
        ended_at = Time.zone.now

        log.update(
          ended_at: ended_at,
          duration_seconds: (ended_at - log.started_at).to_i
        )
      end
    end
  end
end
